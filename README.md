# Seva Connect

Seva Connect is a platform that connects volunteers with volunteering opportunities.

## Project Structure

- `frontend/` - Flutter application (Mobile/Web)
- `backend/` - Node.js + Express API

## Backend Setup

1. `cd backend`
2. Run `npm install`
3. Copy `.env.example` to `.env` and fill in your database credentials and JWT secret.
4. Run `npm run db:generate` to generate the Prisma Client.
5. Run `npm run db:push` to sync the schema with PostgreSQL.
6. Start the development server with `npm run dev` or run `npm start` (after `npm run build`).
7. Run automated test suite: `npm test`

### Demo data

Run `npm run seed:demo` from `backend/` to create the demo NGO and seven open
volunteer opportunities. The seed can be rerun safely; existing demo records
are left unchanged. The demo account can sign in with
`demo-ngo@seva-connect.example` / `SevaDemo2026!`.

## API Endpoints

### Public Endpoints
- `GET /api/health` - API health check
- `POST /api/auth/register` - Register a Volunteer or NGO
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "role": "VOLUNTEER", // or "NGO"
    "name": "Jane Doe",
    "bio": "Optional bio",
    "contactInfo": "Optional contact info"
  }
  ```
- `POST /api/auth/login` - Login with email and password
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
  Returns: JWT token and user profile.

### Protected Endpoints
- `GET /api/auth/me` - Get authenticated user profile (`Authorization: Bearer <token>`)
- `GET /api/protected/volunteer-only` - Restricted to `VOLUNTEER` role
- `GET /api/protected/ngo-only` - Restricted to `NGO` role
- `GET /api/profile/me` - Get the authenticated volunteer's profile
- `PATCH /api/profile/me` - Update the authenticated volunteer's name, bio, location, interests, and skills

## Frontend Setup

1. `cd frontend`
2. Run `flutter pub get`
3. Connect a device or start an emulator/simulator.
4. Run `flutter run`

## Architecture Highlights
- **State Management**: Riverpod
- **Networking**: Dio
- **Routing**: GoRouter
- **Backend Framework**: Express with TypeScript
- **ORM**: Prisma (PostgreSQL)
- **Auth**: JWT + bcrypt
