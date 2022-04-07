CREATE TABLE IF NOT EXISTS guilds (
    guild_id BIGINT PRIMARY KEY,
    moderator_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    moderator_users BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    admin_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    admin_users BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    suggestions_channel_id BIGINT,
    suggestions_safemode BIGINT
);

CREATE TABLE IF NOT EXISTS counting_config (
    guild_id BIGINT PRIMARY KEY
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    channel_id BIGINT NOT NULL,
    lives INT,
    blacklisted_users BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    blacklisted_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    whitelist BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[]
);

CREATE TABLE IF NOT EXISTS levelling_config (
    guild_id BIGINT PRIMARY KEY
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    announce_channel BIGINT,
    xp_modifier FLOAT NOT NULL DEFAULT 1.0,
    blacklisted_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    blacklisted_channels BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    card_background BYTEA,  -- image bytes
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
        -- defaults to true because you'd need to
        -- insert when enabling it, wont be enabled
        -- by default though.
    levelup_messages TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[]
);

CREATE TABLE IF NOT EXISTS levelling_rewards (
    reward_id BIGSERIAL,
    guild_id BIGINT
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    level INT NOT NULL,
    role BIGINT,
    message TEXT,
        -- special level up message?
    PRIMARY KEY (guild_id, role)
);

CREATE TABLE IF NOT EXISTS levelling_users (
    user_id BIGINT PRIMARY KEY,
    guild_id BIGINT NOT NULL
        REFERENCES levelling_config(guild_id)
            ON DELETE CASCADE,
    xp BIGINT NOT NULL DEFAULT 0,
    level INT NOT NULL DEFAULT 0,
    rewards_earned BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[]
        -- references levelling_rewards(reward_id) but there's no
        -- way of doing that in postgresql (yet) .
);

CREATE TABLE IF NOT EXISTS currency_config (
    guild_id BIGINT PRIMARY KEY
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    channel_id BIGINT NOT NULL,
    blacklisted_channels BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    blacklisted_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    bank_limit BIGINT
);

CREATE TABLE IF NOT EXISTS shop (
    item_id BIGSERIAL NOT NULL UNIQUE,
    guild_id BIGINT
        REFERENCES currency_config(guild_id)
            ON DELETE CASCADE,
    name TEXT,
    price BIGINT,
    reward_money FLOAT,
    reward_role BIGINT,
    CONSTRAINT mutually_exclusive_rewards
        CHECK ( (reward_money IS NULL AND reward_role IS NOT NULL) OR
                (reward_money IS NOT NULL AND reward_role IS NULL) )
);

CREATE TABLE IF NOT EXISTS currency_users (
    user_id  BIGINT,
    guild_id BIGINT NOT NULL
        REFERENCES currency_config (guild_id)
            ON DELETE CASCADE,
    wallet BIGINT NOT NULL DEFAULT 0,
    bank BIGINT NOT NULL DEFAULT 0,
    protected BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (user_id, guild_id)
);

CREATE TABLE IF NOT EXISTS inventory (
    user_id BIGINT NOT NULL,
    guild_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL
        REFERENCES shop(item_id)
            ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (user_id, guild_id, item_id),
    CONSTRAINT inv_u_g_fk
        FOREIGN KEY (user_id, guild_id)
            REFERENCES currency_users(user_id, guild_id)
                ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS suggestions (
    suggestion_id BIGSERIAL PRIMARY KEY,
    guild_id BIGINT NOT NULL
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    channel_id BIGINT NOT NULL,
        -- for fetching message purposes in case
        -- guilds(suggestions_channel_id) is deleted.
    user_id BIGINT NOT NULL,
    suggestion TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    up_voters BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    down_voters BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[]
);

CREATE TABLE IF NOT EXISTS ticket_panels (
    panel_id BIGSERIAL PRIMARY KEY,
    guild_id BIGINT
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    category BIGINT NOT NULL,
    message_id BIGINT NOT NULL,
    mod_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[]
);

CREATE TABLE IF NOT EXISTS tickets (
    guild_id BIGINT NOT NULL
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (guild_id, channel_id)
);

CREATE TABLE IF NOT EXISTS stats_tracker (
    guild_id BIGINT
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    time_channel BIGINT,
    members_channel BIGINT,
    milestone_channel BIGINT,
    status_channel BIGINT,
    message_channel BIGINT
);

CREATE TABLE IF NOT EXISTS modmail_config (
    guild_id BIGINT PRIMARY KEY
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    category BIGINT NOT NULL,
    whitelist_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    whitelist_members BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    on_create_pings BOOL NOT NULL DEFAULT FALSE,
    on_message_pings BOOL NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS log_config (
    guild_id BIGINT PRIMARY KEY
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    guild_logs BIGINT,
    message_logs BIGINT,
    user_logs BIGINT,
    moderation_logs BIGINT,
    voice_logs BIGINT
);

CREATE TABLE IF NOT EXISTS custom_commands (
    guild_id BIGINT NOT NULL
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    command_name TEXT NOT NULL,
    command_text TEXT NOT NULL,
    command_creator BIGINT NOT NULL,
    PRIMARY KEY (guild_id, command_name)
);

CREATE TABLE IF NOT EXISTS disabled_commands (
    guild_id BIGINT NOT NULL
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    command_name TEXT NOT NULL,
    whitelist_users BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    whitelist_roles BIGINT[] NOT NULL DEFAULT ARRAY[]::BIGINT[],
    PRIMARY KEY (guild_id, command_name)
);

CREATE TABLE IF NOT EXISTS cases (
    case_id BIGSERIAL NOT NULL UNIQUE,
    case_type TEXT NOT NULL,
    guild_id BIGINT NOT NULL
        REFERENCES guilds(guild_id)
            ON DELETE CASCADE,
    user_id BIGINT NOT NULL,
    moderator_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    last_updated TIMESTAMP,
    expires TIMESTAMP
);

CREATE TABLE IF NOT EXISTS commands(
    user_id bigint NOT NULL,
    command_name TEXT NOT NULL
);

-- LISTENERS
CREATE OR REPLACE FUNCTION update_prefixes_cache()
  RETURNS TRIGGER AS $$
  BEGIN
    IF TG_OP = 'DELETE' THEN
      PERFORM pg_notify('delete_everything', OLD.guild_id::TEXT);
    ELSEIF TG_OP = 'UPDATE' THEN
        IF old.moderator_roles <> new.moderator_roles THEN
          PERFORM pg_notify('update_moderator_roles',
            JSON_BUILD_OBJECT(
                  'guild_id', NEW.guild_id,
                  'ids', NEW.moderator_roles
                )::TEXT
              );
        END IF;
        IF old.moderator_users <> new.moderator_users THEN
          PERFORM pg_notify('update_moderator_users',
            JSON_BUILD_OBJECT(
                  'guild_id', NEW.guild_id,
                  'ids', NEW.moderator_users
                )::TEXT
              );
        END IF;
        IF old.admin_roles <> new.admin_roles THEN
          PERFORM pg_notify('update_admin_roles',
            JSON_BUILD_OBJECT(
                  'guild_id', NEW.guild_id,
                  'ids', NEW.admin_roles
                )::TEXT
              );
        END IF;
        IF old.admin_users <> new.admin_users THEN
          PERFORM pg_notify('update_admin_users',
            JSON_BUILD_OBJECT(
                  'guild_id', NEW.guild_id,
                  'ids', NEW.admin_users
                )::TEXT
              );
        END IF;
    ELSE
      PERFORM pg_notify('insert_everything', NEW.guild_id::TEXT);
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_prefixes_cache_trigger ON guilds;
CREATE TRIGGER update_prefixes_cache_trigger
  AFTER INSERT OR UPDATE OR DELETE
  ON guilds
  FOR EACH ROW
  EXECUTE PROCEDURE update_prefixes_cache();
