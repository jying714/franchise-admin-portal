const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const firestore = admin.firestore();

/**
 * Computes average score per category label in feedback array.
 * @param {Array} feedbacks - Array of feedback objects with
 * "categories" field as ["Label:Score", ...]
 * @return {Object} - Map of category labels to average score.
 */
function categoryAverages(feedbacks) {
  const categoryMap = {};
  const counts = {};
  feedbacks.forEach((fb) => {
    if (Array.isArray(fb.categories)) {
      fb.categories.forEach((c) => {
        // Category in "Label:Score" format (ex: "Ease of use:5")
        const parts = c.split(":");
        if (parts.length === 2) {
          const key = parts[0].trim();
          const score = parseFloat(parts[1]);
          if (!isNaN(score)) {
            categoryMap[key] = (categoryMap[key] || 0) + score;
            counts[key] = (counts[key] || 0) + 1;
          }
        }
      });
    }
  });
  // Return average per category
  const avg = {};
  Object.keys(categoryMap).forEach((k) => {
    avg[k] = counts[k] ? categoryMap[k] / counts[k] : null;
  });
  return avg;
}

exports.rollupAnalyticsSummaries =
  functions.https.onRequest(async (req, res) => {
    try {
      console.log("Manual analytics rollup trigger...");

      // --- Fetch all orders ---
      const ordersSnap = await firestore.collection("orders").get();
      const allOrders = [];
      const franchiseIds = new Set();

      ordersSnap.forEach((orderDoc) => {
        const order = orderDoc.data();
        const franchiseId = order.franchiseId || "default";
        order.franchiseId = franchiseId;
        franchiseIds.add(franchiseId);
        allOrders.push(order);
      });

      // --- Fetch all feedbacks ---
      const feedbackSnap = await firestore.collection("feedback").get();
      const allFeedbacks = feedbackSnap.docs.map((doc) => {
        const fb = doc.data();
        fb.id = doc.id;
        return fb;
      });

      // --- For each franchise, roll up analytics ---
      for (const franchiseId of franchiseIds) {
        // Time window: current month
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, "0");
        const nextMonth = String(now.getMonth() + 2).padStart(2, "0");
        const period = `${year}-${month}`;
        const periodStart = new Date(`${year}-${month}-01T00:00:00.000Z`);
        const periodEnd = new Date(`${year}-${nextMonth}-01T00:00:00.000Z`);

        // --- Orders for this franchise and month
        const franchiseOrders = allOrders.filter((order) => {
          let ts;
          if (order.timestamp && typeof order.timestamp.toDate === "function") {
            ts = order.timestamp.toDate();
          } else if (order.timestamp && order.timestamp._seconds) {
            ts = new Date(order.timestamp._seconds * 1000);
          } else {
            ts = new Date(order.timestamp);
          }
          const isMonth =
            ts >= new Date(`${year}-${month}-01T00:00:00.000Z`) &&
            ts < new Date(`${year}-${nextMonth}-01T00:00:00.000Z`);
          return order.franchiseId === franchiseId && isMonth;
        });

        // --- Feedbacks for this franchise and period
        // --- Feedbacks for this franchise and period
        const orderIdsThisPeriod = franchiseOrders.map((order) => order.id);
        const feedbacksThisPeriod = allFeedbacks.filter((fb) => {
          // Linked to order in this period
          const linkedToOrder = fb.orderId && orderIdsThisPeriod.
              includes(fb.orderId);

          // Parse feedback timestamp
          let feedbackTimestamp = null;
          if (fb.timestamp && typeof fb.timestamp.toDate === "function") {
            feedbackTimestamp = fb.timestamp.toDate();
          } else if (fb.timestamp && fb.timestamp._seconds) {
            feedbackTimestamp = new Date(fb.timestamp._seconds * 1000);
          } else if (fb.timestamp) {
            feedbackTimestamp = new Date(fb.timestamp);
          }

          const isPeriod =
          feedbackTimestamp &&
          feedbackTimestamp >= periodStart &&
          feedbackTimestamp < periodEnd;

          const included =
          (linkedToOrder || isPeriod) &&
          (fb.franchiseId === undefined || fb.franchiseId === franchiseId);

          if (included) {
            console.log(
                `[Feedback Included] id=${fb.id} | orderId=${fb.orderId} |
                 mode=${fb.feedbackMode} | linkedToOrder=${linkedToOrder} |
                  isPeriod=${isPeriod} |
                   feedbackTimestamp=${feedbackTimestamp}`,
            );
          } else {
            console.log(
                `[Feedback Skipped] id=${fb.id} | orderId=${fb.orderId} |
                 mode=${fb.feedbackMode} | linkedToOrder=${linkedToOrder} |
                  isPeriod=${isPeriod} |
                   feedbackTimestamp=${feedbackTimestamp}`,
            );
          }
          return included;
        });
        console.log(
            `Total feedbacks for franchise=${franchiseId}
             and period=${period}: ${feedbacksThisPeriod.length}`,
        );


        // --- All analytics as before ---
        const totalOrders = franchiseOrders.length;
        let totalRevenue = 0;
        const itemCounts = {};
        const userIds = new Set();
        const statusCounts = {};
        let cancelledOrders = 0;
        const toppingCounts = {};
        const addOnCounts = {};
        let addOnRevenue = 0;
        const comboCounts = {};

        franchiseOrders.forEach((order) => {
          totalRevenue += order.total || 0;
          if (order.userId) userIds.add(order.userId);
          if (order.status) {
            statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
            if (order.status === "cancelled") cancelledOrders++;
          }
          if (order.items && Array.isArray(order.items)) {
            order.items.forEach((item) => {
              if (!itemCounts[item.name]) itemCounts[item.name] = 0;
              itemCounts[item.name] += item.quantity || 1;
              const custom = item.customizations || {};
              if (Array.isArray(custom.toppings)) {
                custom.toppings.forEach((topping) => {
                  toppingCounts[topping] =
                    (toppingCounts[topping] || 0) + (item.quantity || 1);
                });
              }
              if (Array.isArray(custom.addOns)) {
                custom.addOns.forEach((addOn) => {
                  if (!addOn.name) return;
                  addOnCounts[addOn.name] =
                    (addOnCounts[addOn.name] || 0) + (item.quantity || 1);
                  addOnRevenue += (addOn.price || 0) * (item.quantity || 1);
                });
              }
              if (custom.comboSignature) {
                comboCounts[custom.comboSignature] =
                  (comboCounts[custom.comboSignature] || 0) +
                  (item.quantity || 1);
              }
            });
          }
        });

        // Most popular item
        let mostPopularItem = "-";
        let mostPopularCount = 0;
        Object.entries(itemCounts).forEach(([name, count]) => {
          if (count > mostPopularCount) {
            mostPopularCount = count;
            mostPopularItem = name;
          }
        });

        const averageOrderValue = totalOrders ? totalRevenue / totalOrders : 0;
        const uniqueCustomers = userIds.size;

        // --- FEEDBACK AGGREGATION (NEW SECTION) ---
        // Separate feedbacks
        const orderFeedbacks = feedbacksThisPeriod.filter(
            (fb) => (fb.feedbackMode || "").toLowerCase() === "orderexperience",
        );
        const appFeedbacks = feedbacksThisPeriod.filter(
            (fb) => (fb.feedbackMode || "").toLowerCase() === "ordering",
        );
        // Overall
        const allStars = feedbacksThisPeriod
            .map((fb) => fb.rating)
            .filter((r) => typeof r === "number");
        const orderStars = orderFeedbacks
            .map((fb) => fb.rating)
            .filter((r) => typeof r === "number");
        const appStars = appFeedbacks
            .map((fb) => fb.rating)
            .filter((r) => typeof r === "number");
        const averageStarRating =
          allStars.length > 0 ?
            allStars.reduce((a, b) => a + b, 0) / allStars.length :
            null;

        // --- Participation rate: percent of orders with feedback
        const participationRate =
          totalOrders > 0 ? feedbacksThisPeriod.length / totalOrders : 0;

        // Build feedbackStats
        const feedbackStats = {
          averageStarRating,
          totalFeedbacks: feedbacksThisPeriod.length,
          participationRate,
          // --- Order feedback ---
          orderFeedback: {
            avgStarRating:
              orderStars.length > 0 ?
                orderStars.reduce((a, b) => a + b, 0) / orderStars.length :
                null,
            count: orderFeedbacks.length,
            avgCategories: categoryAverages(orderFeedbacks),
          },
          // --- App feedback ---
          appFeedback: {
            avgStarRating:
              appStars.length > 0 ?
                appStars.reduce((a, b) => a + b, 0) / appStars.length :
                null,
            count: appFeedbacks.length,
            avgCategories: categoryAverages(appFeedbacks),
          },
        };

        // --- Build analytics summary ---
        const summary = {
          franchiseId,
          period,
          totalOrders,
          totalRevenue,
          averageOrderValue,
          uniqueCustomers,
          mostPopularItem,
          cancelledOrders,
          orderStatusBreakdown: statusCounts,
          toppingCounts,
          addOnCounts,
          addOnRevenue,
          comboCounts,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          // --- Feedback analytics ---
          feedbackStats,
        };
        console.log("FeedbackStats for summary:",
            JSON.stringify(feedbackStats, null, 2));
        // --- Write summary ---
        const summaryDocId = `${franchiseId}_${period}`;
        await firestore
            .collection("analytics_summaries")
            .doc(summaryDocId)
            .set(summary, {merge: true});

        console.log(
            `Analytics summary written for ${franchiseId} / ${period}`,
        );
      }

      res.status(200).send("Analytics summary rollup complete!");
    } catch (err) {
      console.error(err);
      res.status(500).send("Error running analytics rollup.");
    }
  });
