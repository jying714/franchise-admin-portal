# Legal & Compliance Documentation
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: July 19, 2026

## Overview
This document outlines key legal and compliance considerations for the SaaS platform.  
**Note**: This is a starting template. Consult a lawyer before public launch.

## 1. Terms of Service (ToS)
- Must cover: data ownership, uptime SLA, termination rights, acceptable use, subscription billing, refunds.
- Users own their menu data and branding; platform has license to host/process.
- Automatic renewal disclosure and cancellation policy required.

## 2. Privacy Policy
- Data collected: orders, menus, analytics, user profiles.
- Firebase/Firebase Auth handling.
- Compliance with CCPA (California) and general US privacy laws.
- Data sharing only as necessary for service delivery (Stripe, etc.).

## 3. Payment Processing (Stripe)
- PCI DSS compliance handled by Stripe (no card data stored by us).
- Clear billing, failed payment, and dunning policies.
- Subscription tiers and feature gating must be accurately described.

## 4. Data Security & Liability
- Firestore security rules enforce franchise scoping (least privilege).
- Regular security audits recommended.
- Limit liability for data loss, downtime, or business interruption via ToS.
- Cyber liability insurance consideration for production.

## 5. Intellectual Property
- Users warrant they own rights to uploaded logos, images, menus.
- Platform IP protected.

## 6. Compliance Roadmap
**MVP**:
- Basic ToS and Privacy Policy (use templates + customize)
- Stripe agreement compliance
- Firestore security rules hardening

**Post-MVP**:
- Full SOC2 audit (for enterprise trust)
- Accessibility (WCAG basics)
- Sales tax handling on SaaS fees (TN rules)
- Data export / deletion rights

## 7. Recommendations
- Use services like Termly or Iubenda for initial ToS/Privacy templates
- Review with legal counsel before accepting real customers
- Document all major compliance decisions here

**Status**: Starter template — expand before public release.

**Last Updated**: July 19, 2026