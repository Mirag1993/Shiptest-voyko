export type Data = {
  points: number;
  message: string;
  faction_theme?: string;
  supplies?: Record<string, any>;
  self_paid?: boolean;
  app_cost?: boolean;
  blockade?: boolean;
  max_cart_items?: number;
  search_results_limit?: number;
  enable_cart_persistence?: boolean;
};
