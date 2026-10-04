import { Profile } from "@prisma/client";

export interface RequestAuth {
  userId: string;
  email?: string | null;
}

declare global {
  namespace Express {
    interface Request {
      requestId: string;
      auth?: RequestAuth;
      profile?: Profile;
    }
  }
}
