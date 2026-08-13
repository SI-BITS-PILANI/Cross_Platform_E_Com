export type AuthenticatedUser = {
  sub: string;
  username: string;
  roles: string[];
};

export type UserRecord = {
  id: string;
  username: string;
  email: string;
  password_hash: string;
  roles: string[];
  created_at: string;
  updated_at: string;
};
