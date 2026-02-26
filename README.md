# ClinicCore

**ClinicCore** — The core boilerplate powering all ClinicDev SaaS products.

Built by [ClinicDev](https://clinicdev.com) — Powering your clinic systems.

---

## Local Development Setup (Docker)

**Prerequisites:** Docker Desktop

```bash
# 1. Clone and start the stack
docker compose up --build

# 2. Set up the database
docker compose exec web bin/rails db:create db:migrate db:seed

# 3. Visit http://localhost:3000
```

### Default Login

| Email                  | Password       | Role       |
|------------------------|----------------|------------|
| admin@clinicdev.com    | Password1!Pw   | SuperAdmin |

---

## Environment Variables

| Variable                | Required | Description                                      |
|-------------------------|----------|--------------------------------------------------|
| `DATABASE_URL`          | Yes      | PostgreSQL connection URL                        |
| `RAILS_MASTER_KEY`      | Yes      | Rails credentials key (`config/master.key`)      |
| `GOOGLE_CLIENT_ID`      | No       | Google OAuth2 client ID                          |
| `GOOGLE_CLIENT_SECRET`  | No       | Google OAuth2 client secret                      |
| `POSTGRES_PASSWORD`     | Yes*     | Postgres password for Kamal accessory            |
| `KAMAL_REGISTRY_USERNAME` | Yes*   | GitHub username for ghcr.io                      |
| `KAMAL_REGISTRY_PASSWORD` | Yes*   | GitHub PAT (write:packages scope)                |

\* Required for production deployment only.

---

## Role Hierarchy

| Role       | Level | Capabilities                                           |
|------------|-------|--------------------------------------------------------|
| SuperAdmin | 100   | Full access — all resources including Roles & Settings |
| Admin      | 50    | Manage users and content; cannot modify Roles/Settings |
| Client     | 10    | Read-only access to Books and Authors                  |

Users are created unapproved. A SuperAdmin or Admin must approve them and assign a role.

---

## Permission System

Permissions are normalized via a `Permission` model (resource + action pairs) assigned to roles through `RolePermission`. The `ALL_PERMISSIONS` constant in `app/models/permission.rb` defines all valid resource/action pairs.

Seed with `bin/rails db:seed` to populate roles, permissions, and the default SuperAdmin user.

---

## Running Tests

```bash
docker compose exec web bundle exec rspec --format documentation
```

---

## Deployment (Kamal)

### First Deploy

```bash
# 1. Copy .kamal/secrets and fill in all values
# 2. Update config/deploy.yml (replace GITHUB_USERNAME, DROPLET_IP, YOUR_DOMAIN_HERE)
# 3. Initial setup on the server
kamal setup

# 4. Deploy
kamal deploy
```

### Ongoing Deploys

Push to `main` — GitHub Actions runs tests then auto-deploys via `kamal deploy`.

---

## Tech Stack

- **Framework:** Rails 8.1.2
- **Database:** PostgreSQL
- **Frontend:** Hotwire (Turbo + Stimulus) + Tailwind CSS
- **Auth:** authentication-zero + OmniAuth Google OAuth2 + 2FA (TOTP)
- **Authorization:** Role-based with hierarchy levels + normalized RBAC permissions
- **Soft Delete:** Discard gem (Users, Books, Authors, Scouts)
- **Pagination:** Pagy
- **Rate Limiting:** Rack::Attack
- **Testing:** RSpec + FactoryBot + Shoulda-Matchers + Faker + Capybara + SimpleCov
- **Deployment:** Kamal + GitHub Container Registry + GitHub Actions CI/CD

---

> **ClinicDev Internal Use** — This boilerplate is the foundation for all ClinicDev SaaS products. Do not distribute externally.
