export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      app_health: {
        Row: {
          created_at: string
          id: number
          status: string
        }
        Insert: {
          created_at?: string
          id: number
          status: string
        }
        Update: {
          created_at?: string
          id?: number
          status?: string
        }
        Relationships: []
      }
      dining_tables: {
        Row: {
          capacity: number | null
          code: string
          created_at: string
          display_name: string
          id: string
          operational_status: Database["public"]["Enums"]["table_operational_status"]
          restaurant_id: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          capacity?: number | null
          code: string
          created_at?: string
          display_name: string
          id?: string
          operational_status?: Database["public"]["Enums"]["table_operational_status"]
          restaurant_id: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          capacity?: number | null
          code?: string
          created_at?: string
          display_name?: string
          id?: string
          operational_status?: Database["public"]["Enums"]["table_operational_status"]
          restaurant_id?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "dining_tables_restaurant_id_fkey"
            columns: ["restaurant_id"]
            isOneToOne: false
            referencedRelation: "restaurants"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          full_name: string
          id: string
          is_active: boolean
          updated_at: string
        }
        Insert: {
          created_at?: string
          full_name?: string
          id: string
          is_active?: boolean
          updated_at?: string
        }
        Update: {
          created_at?: string
          full_name?: string
          id?: string
          is_active?: boolean
          updated_at?: string
        }
        Relationships: []
      }
      restaurant_staff: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          profile_id: string
          restaurant_id: string
          role: Database["public"]["Enums"]["staff_role"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          profile_id: string
          restaurant_id: string
          role: Database["public"]["Enums"]["staff_role"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          profile_id?: string
          restaurant_id?: string
          role?: Database["public"]["Enums"]["staff_role"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "restaurant_staff_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "restaurant_staff_restaurant_id_fkey"
            columns: ["restaurant_id"]
            isOneToOne: false
            referencedRelation: "restaurants"
            referencedColumns: ["id"]
          },
        ]
      }
      restaurants: {
        Row: {
          created_at: string
          currency_code: string
          id: string
          is_active: boolean
          name: string
          slug: string
          timezone: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          currency_code?: string
          id?: string
          is_active?: boolean
          name: string
          slug: string
          timezone?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          currency_code?: string
          id?: string
          is_active?: boolean
          name?: string
          slug?: string
          timezone?: string
          updated_at?: string
        }
        Relationships: []
      }
      session_controller_tokens: {
        Row: {
          created_at: string
          created_from_request_id: string
          device_id: string
          expires_at: string
          id: string
          invalidated_at: string | null
          issued_at: string
          status: Database["public"]["Enums"]["controller_token_status"]
          table_session_id: string
          token_hash: string
        }
        Insert: {
          created_at?: string
          created_from_request_id: string
          device_id: string
          expires_at: string
          id?: string
          invalidated_at?: string | null
          issued_at?: string
          status?: Database["public"]["Enums"]["controller_token_status"]
          table_session_id: string
          token_hash: string
        }
        Update: {
          created_at?: string
          created_from_request_id?: string
          device_id?: string
          expires_at?: string
          id?: string
          invalidated_at?: string | null
          issued_at?: string
          status?: Database["public"]["Enums"]["controller_token_status"]
          table_session_id?: string
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "session_controller_tokens_created_from_request_id_fkey"
            columns: ["created_from_request_id"]
            isOneToOne: true
            referencedRelation: "table_control_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "session_controller_tokens_table_session_id_fkey"
            columns: ["table_session_id"]
            isOneToOne: false
            referencedRelation: "table_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      table_control_requests: {
        Row: {
          confirmation_code: string
          created_at: string
          device_id: string
          dining_table_id: string
          expires_at: string
          id: string
          request_type: Database["public"]["Enums"]["table_control_request_type"]
          requested_at: string
          resolution_reason: string | null
          resolved_at: string | null
          resolved_by: string | null
          status: Database["public"]["Enums"]["table_control_request_status"]
          table_session_id: string | null
          token_hash: string
          updated_at: string
        }
        Insert: {
          confirmation_code: string
          created_at?: string
          device_id: string
          dining_table_id: string
          expires_at: string
          id?: string
          request_type: Database["public"]["Enums"]["table_control_request_type"]
          requested_at?: string
          resolution_reason?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: Database["public"]["Enums"]["table_control_request_status"]
          table_session_id?: string | null
          token_hash: string
          updated_at?: string
        }
        Update: {
          confirmation_code?: string
          created_at?: string
          device_id?: string
          dining_table_id?: string
          expires_at?: string
          id?: string
          request_type?: Database["public"]["Enums"]["table_control_request_type"]
          requested_at?: string
          resolution_reason?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: Database["public"]["Enums"]["table_control_request_status"]
          table_session_id?: string | null
          token_hash?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_control_requests_dining_table_id_fkey"
            columns: ["dining_table_id"]
            isOneToOne: false
            referencedRelation: "dining_tables"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_control_requests_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_control_requests_table_session_id_fkey"
            columns: ["table_session_id"]
            isOneToOne: false
            referencedRelation: "table_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      table_qr_tokens: {
        Row: {
          created_at: string
          dining_table_id: string
          id: string
          is_active: boolean
          public_token: string
          revoked_at: string | null
        }
        Insert: {
          created_at?: string
          dining_table_id: string
          id?: string
          is_active?: boolean
          public_token?: string
          revoked_at?: string | null
        }
        Update: {
          created_at?: string
          dining_table_id?: string
          id?: string
          is_active?: boolean
          public_token?: string
          revoked_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "table_qr_tokens_dining_table_id_fkey"
            columns: ["dining_table_id"]
            isOneToOne: false
            referencedRelation: "dining_tables"
            referencedColumns: ["id"]
          },
        ]
      }
      table_session_status_history: {
        Row: {
          changed_at: string
          changed_by: string | null
          id: number
          new_status: Database["public"]["Enums"]["table_session_status"]
          previous_status:
            | Database["public"]["Enums"]["table_session_status"]
            | null
          table_session_id: string
        }
        Insert: {
          changed_at?: string
          changed_by?: string | null
          id?: never
          new_status: Database["public"]["Enums"]["table_session_status"]
          previous_status?:
            | Database["public"]["Enums"]["table_session_status"]
            | null
          table_session_id: string
        }
        Update: {
          changed_at?: string
          changed_by?: string | null
          id?: never
          new_status?: Database["public"]["Enums"]["table_session_status"]
          previous_status?:
            | Database["public"]["Enums"]["table_session_status"]
            | null
          table_session_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_session_status_history_changed_by_fkey"
            columns: ["changed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_session_status_history_table_session_id_fkey"
            columns: ["table_session_id"]
            isOneToOne: false
            referencedRelation: "table_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      table_sessions: {
        Row: {
          closed_at: string | null
          closed_by: string | null
          controller_version: number
          created_at: string
          dining_table_id: string
          id: string
          opened_at: string
          opened_by: string
          status: Database["public"]["Enums"]["table_session_status"]
          updated_at: string
        }
        Insert: {
          closed_at?: string | null
          closed_by?: string | null
          controller_version?: number
          created_at?: string
          dining_table_id: string
          id?: string
          opened_at?: string
          opened_by: string
          status?: Database["public"]["Enums"]["table_session_status"]
          updated_at?: string
        }
        Update: {
          closed_at?: string | null
          closed_by?: string | null
          controller_version?: number
          created_at?: string
          dining_table_id?: string
          id?: string
          opened_at?: string
          opened_by?: string
          status?: Database["public"]["Enums"]["table_session_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_sessions_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_sessions_dining_table_id_fkey"
            columns: ["dining_table_id"]
            isOneToOne: false
            referencedRelation: "dining_tables"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_sessions_opened_by_fkey"
            columns: ["opened_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      approve_table_activation: {
        Args: { p_request_id: string }
        Returns: {
          controller_version: number
          request_status: Database["public"]["Enums"]["table_control_request_status"]
          table_session_id: string
        }[]
      }
      approve_table_control_transfer: {
        Args: { p_request_id: string }
        Returns: {
          controller_version: number
          request_status: Database["public"]["Enums"]["table_control_request_status"]
          table_session_id: string
        }[]
      }
      close_table_session: {
        Args: { p_table_session_id: string }
        Returns: Database["public"]["Enums"]["table_session_status"]
      }
      get_controller_session: {
        Args: { p_controller_token: string; p_qr_token: string }
        Returns: {
          controller_version: number
          restaurant_name: string
          restaurant_slug: string
          session_status: Database["public"]["Enums"]["table_session_status"]
          table_display_name: string
          table_session_id: string
        }[]
      }
      get_public_table_context: {
        Args: { p_qr_token: string }
        Returns: {
          has_open_session: boolean
          restaurant_name: string
          restaurant_slug: string
          table_display_name: string
          table_operational_status: Database["public"]["Enums"]["table_operational_status"]
        }[]
      }
      get_table_control_request_status: {
        Args: { p_controller_token: string; p_request_id: string }
        Returns: {
          expires_at: string
          request_status: Database["public"]["Enums"]["table_control_request_status"]
          request_type: Database["public"]["Enums"]["table_control_request_type"]
          table_session_id: string
        }[]
      }
      reject_table_control_request: {
        Args: { p_reason?: string; p_request_id: string }
        Returns: Database["public"]["Enums"]["table_control_request_status"]
      }
      request_table_activation: {
        Args: { p_device_id: string; p_qr_token: string }
        Returns: {
          confirmation_code: string
          controller_token: string
          expires_at: string
          request_id: string
        }[]
      }
      request_table_control_transfer: {
        Args: { p_device_id: string; p_qr_token: string }
        Returns: {
          confirmation_code: string
          controller_token: string
          expires_at: string
          request_id: string
        }[]
      }
    }
    Enums: {
      controller_token_status: "ACTIVE" | "REVOKED" | "EXPIRED"
      staff_role: "ADMIN" | "WAITER" | "KITCHEN"
      table_control_request_status:
        | "PENDING"
        | "APPROVED"
        | "REJECTED"
        | "EXPIRED"
        | "CANCELLED"
      table_control_request_type: "ACTIVATE_TABLE" | "TRANSFER_CONTROL"
      table_operational_status: "ACTIVE" | "OUT_OF_SERVICE"
      table_session_status:
        | "ACTIVE"
        | "BILL_REQUESTED"
        | "PAYMENT_PENDING"
        | "CLOSED"
        | "CANCELLED"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      controller_token_status: ["ACTIVE", "REVOKED", "EXPIRED"],
      staff_role: ["ADMIN", "WAITER", "KITCHEN"],
      table_control_request_status: [
        "PENDING",
        "APPROVED",
        "REJECTED",
        "EXPIRED",
        "CANCELLED",
      ],
      table_control_request_type: ["ACTIVATE_TABLE", "TRANSFER_CONTROL"],
      table_operational_status: ["ACTIVE", "OUT_OF_SERVICE"],
      table_session_status: [
        "ACTIVE",
        "BILL_REQUESTED",
        "PAYMENT_PENDING",
        "CLOSED",
        "CANCELLED",
      ],
    },
  },
} as const
