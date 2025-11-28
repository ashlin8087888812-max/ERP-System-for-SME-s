# Roadmap

## Future Features

- [ ] **Billing Integration**: Stripe/PayPal integration for subscription management.
- [ ] **Analytics ETL**: Extract data from Odoo to a data warehouse (Snowflake/BigQuery) for analytics.
- [ ] **Tenant Migration Tooling**: Automated scripts to move tenant databases between hosts.
- [ ] **Advanced Monitoring**: Grafana dashboards for Celery queues and API latency.
- [ ] **Mobile Push Notifications**: Integrate Firebase (FCM) for push notifications on job updates.

## Improvements

- [ ] **Rate Limiting**: Implement Redis-based rate limiting for all API endpoints.
- [ ] **Caching**: Cache Odoo product/partner data in Redis to reduce XML-RPC calls.
- [ ] **CI/CD**: Full CI/CD pipeline with deployment to Kubernetes.
