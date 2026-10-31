ALTER TABLE "chatbot_messages"
ADD COLUMN "sequence" BIGSERIAL NOT NULL;

DROP INDEX "chatbot_messages_conversation_id_created_at_idx";
CREATE UNIQUE INDEX "chatbot_messages_sequence_key" ON "chatbot_messages"("sequence");
CREATE INDEX "chatbot_messages_conversation_id_sequence_idx"
ON "chatbot_messages"("conversation_id", "sequence");

CREATE TABLE "chatbot_rate_limits" (
  "user_id" UUID NOT NULL,
  "last_finished_at" TIMESTAMPTZ(3),
  "in_flight_until" TIMESTAMPTZ(3) NOT NULL,
  CONSTRAINT "chatbot_rate_limits_pkey" PRIMARY KEY ("user_id")
);

ALTER TABLE "chatbot_rate_limits"
ADD CONSTRAINT "chatbot_rate_limits_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "profiles"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "chatbot_rate_limits" ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "chatbot_rate_limits" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "chatbot_rate_limits" FROM authenticated;
  END IF;
END;
$$;
