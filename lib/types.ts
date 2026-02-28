// ============================================================
// Database types matching Supabase schema
// ============================================================

export type RatingCategory =
  | "friturisme"
  | "service"
  | "prijs_kwaliteit"
  | "friet"
  | "bicky"
  | "snacks"
  | "sauzen";

export type FrituurPlan = "free" | "premium";

// ---- Row types ----

export interface User {
  id: string;
  email: string;
  name: string;
  avatar_url: string | null;
  favorite_snacks: string[];
  reviewer_type: string;
  created_at: string;
}

export interface Frituur {
  id: string;
  name: string;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  google_place_id: string | null;
  phone: string | null;
  opening_hours: OpeningHours;
  claimed: boolean;
  claimed_by: string | null;
  plan: FrituurPlan;
  verified: boolean;
  created_at: string;
}

export interface CheckIn {
  id: string;
  user_id: string;
  frituur_id: string;
  snacks: string[];
  sauces: string[];
  text: string | null;
  photo_url: string | null;
  created_at: string;
}

export interface Rating {
  id: string;
  check_in_id: string;
  category: RatingCategory;
  score: number; // 1-5
}

export interface OwnerReply {
  id: string;
  check_in_id: string;
  user_id: string;
  text: string;
  created_at: string;
}

// ---- Supporting types ----

export interface OpeningHours {
  ma?: string;
  di?: string;
  wo?: string;
  do?: string;
  vr?: string;
  za?: string;
  zo?: string;
}

// ---- Joined/computed types for UI ----

export interface CheckInWithDetails extends CheckIn {
  user: User;
  frituur: Frituur;
  ratings: Rating[];
  owner_replies: OwnerReply[];
}

export interface FrituurWithStats extends Frituur {
  avg_ratings: CategoryAverage[];
  total_check_ins: number;
}

export interface CategoryAverage {
  category: RatingCategory;
  avg_score: number;
  total_ratings: number;
}

// ---- Insert types (omit server-generated fields) ----

export type UserInsert = Omit<User, "created_at">;
export type FrituurInsert = Omit<Frituur, "id" | "created_at">;
export type CheckInInsert = Omit<CheckIn, "id" | "created_at">;
export type RatingInsert = Omit<Rating, "id">;
export type OwnerReplyInsert = Omit<OwnerReply, "id" | "created_at">;

// ---- Update types ----

export type UserUpdate = Partial<Omit<User, "id" | "email" | "created_at">>;
export type FrituurUpdate = Partial<
  Omit<Frituur, "id" | "created_at">
>;
export type CheckInUpdate = Partial<
  Omit<CheckIn, "id" | "user_id" | "created_at">
>;

// ---- Supabase generated database type ----

export interface Database {
  public: {
    Tables: {
      users: {
        Row: User;
        Insert: UserInsert;
        Update: UserUpdate;
      };
      frituren: {
        Row: Frituur;
        Insert: FrituurInsert;
        Update: FrituurUpdate;
      };
      check_ins: {
        Row: CheckIn;
        Insert: CheckInInsert;
        Update: CheckInUpdate;
      };
      ratings: {
        Row: Rating;
        Insert: RatingInsert;
        Update: Partial<RatingInsert>;
      };
      owner_replies: {
        Row: OwnerReply;
        Insert: OwnerReplyInsert;
        Update: Partial<Omit<OwnerReply, "id" | "created_at">>;
      };
    };
    Enums: {
      rating_category: RatingCategory;
      frituur_plan: FrituurPlan;
    };
  };
}
