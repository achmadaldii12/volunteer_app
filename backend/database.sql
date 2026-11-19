-- ============================================================================
-- SKEMA DATABASE VOLUNTEER  (MySQL 5.7+/8 atau MariaDB 10.3+)
-- Dijalankan otomatis oleh setup.php, atau import manual lewat phpMyAdmin/HeidiSQL.
-- Kolom "data" menyimpan JSON lengkap dari aplikasi Flutter supaya semua
-- fitur (termasuk fitur baru) tetap tersimpan utuh.
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id            VARCHAR(64)  NOT NULL PRIMARY KEY,
  name          VARCHAR(150) NOT NULL,
  email         VARCHAR(190) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone         VARCHAR(40)  NOT NULL DEFAULT '',
  city          VARCHAR(120) NOT NULL DEFAULT '',
  bio           TEXT NULL,
  role          VARCHAR(20)  NOT NULL DEFAULT 'volunteer',
  avatar_url    VARCHAR(255) NOT NULL DEFAULT '',
  past_events   INT NOT NULL DEFAULT 0,
  past_hours    INT NOT NULL DEFAULT 0,
  past_points   INT NOT NULL DEFAULT 0,
  past_impact   INT NOT NULL DEFAULT 0,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS api_tokens (
  token_hash CHAR(64)    NOT NULL PRIMARY KEY,
  user_id    VARCHAR(64) NOT NULL,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME    NOT NULL,
  KEY idx_tokens_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS events (
  id               VARCHAR(64)  NOT NULL PRIMARY KEY,
  owner_id         VARCHAR(64)  NOT NULL DEFAULT '',
  title            VARCHAR(255) NOT NULL DEFAULT '',
  category         VARCHAR(60)  NOT NULL DEFAULT '',
  organizer        VARCHAR(190) NOT NULL DEFAULT '',
  location         VARCHAR(255) NOT NULL DEFAULT '',
  description      TEXT NULL,
  image_url        VARCHAR(255) NOT NULL DEFAULT '',
  event_time       VARCHAR(60)  NOT NULL DEFAULT '',
  event_date       DATETIME NULL,
  quota            INT NOT NULL DEFAULT 0,
  base_participants INT NOT NULL DEFAULT 0,
  points           INT NOT NULL DEFAULT 0,
  hours            INT NOT NULL DEFAULT 0,
  impact           INT NOT NULL DEFAULT 0,
  price            INT NOT NULL DEFAULT 0,
  status           VARCHAR(20)  NOT NULL DEFAULT 'published',
  deadline         DATETIME NULL,
  require_approval TINYINT(1) NOT NULL DEFAULT 0,
  is_deleted       TINYINT(1) NOT NULL DEFAULT 0,
  data             LONGTEXT NULL,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_events_owner (owner_id),
  KEY idx_events_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS registrations (
  id             VARCHAR(64) NOT NULL PRIMARY KEY,
  user_id        VARCHAR(64) NOT NULL,
  event_id       VARCHAR(64) NOT NULL,
  code           VARCHAR(40) NOT NULL DEFAULT '',
  status         VARCHAR(20) NOT NULL DEFAULT 'registered',
  approval       VARCHAR(20) NOT NULL DEFAULT '',
  checked_in_at  VARCHAR(40) NOT NULL DEFAULT '',
  checked_out_at VARCHAR(40) NOT NULL DEFAULT '',
  registered_at  DATETIME NULL,
  data           LONGTEXT NULL,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_reg_user (user_id),
  KEY idx_reg_event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notifications (
  id         VARCHAR(64) NOT NULL PRIMARY KEY,
  user_id    VARCHAR(64) NOT NULL,
  title      VARCHAR(255) NOT NULL DEFAULT '',
  body       TEXT NULL,
  kind       VARCHAR(80) NOT NULL DEFAULT 'info',
  is_read    TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NULL,
  data       LONGTEXT NULL,
  KEY idx_notif_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS point_entries (
  id         VARCHAR(64) NOT NULL PRIMARY KEY,
  user_id    VARCHAR(64) NOT NULL,
  event_id   VARCHAR(64) NULL,
  type       VARCHAR(30) NOT NULL DEFAULT 'event',
  points     INT NOT NULL DEFAULT 0,
  verified   TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NULL,
  data       LONGTEXT NULL,
  KEY idx_points_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS certificates (
  id        VARCHAR(64) NOT NULL PRIMARY KEY,
  reg_id    VARCHAR(64) NOT NULL,
  user_id   VARCHAR(64) NOT NULL,
  event_id  VARCHAR(64) NOT NULL,
  number    VARCHAR(60) NOT NULL DEFAULT '',
  issued_at DATETIME NULL,
  data      LONGTEXT NULL,
  KEY idx_cert_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS org_messages (
  id              VARCHAR(64) NOT NULL PRIMARY KEY,
  owner_id        VARCHAR(64) NOT NULL,
  kind            VARCHAR(30) NOT NULL DEFAULT '',
  title           VARCHAR(255) NOT NULL DEFAULT '',
  body            TEXT NULL,
  event_id        VARCHAR(64) NULL,
  recipient_count INT NOT NULL DEFAULT 0,
  created_at      DATETIME NULL,
  data            LONGTEXT NULL,
  KEY idx_orgmsg_owner (owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS feedbacks (
  id          VARCHAR(64) NOT NULL PRIMARY KEY,
  user_id     VARCHAR(64) NOT NULL,
  event_title VARCHAR(255) NOT NULL DEFAULT '',
  rating      INT NOT NULL DEFAULT 0,
  text        TEXT NULL,
  created_at  DATETIME NULL,
  data        LONGTEXT NULL,
  KEY idx_fb_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS comm_messages (
  id          VARCHAR(64) NOT NULL PRIMARY KEY,
  room_id     VARCHAR(40) NOT NULL DEFAULT 'umum',
  sender_id   VARCHAR(64) NOT NULL,
  sender_name VARCHAR(150) NOT NULL DEFAULT '',
  text        TEXT NULL,
  type        VARCHAR(20) NOT NULL DEFAULT 'text',
  event_id    VARCHAR(64) NULL,
  reply_to_id VARCHAR(64) NULL,
  image_url   VARCHAR(255) NOT NULL DEFAULT '',
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  DATETIME NULL,
  data        LONGTEXT NULL,
  KEY idx_cm_room (room_id),
  KEY idx_cm_sender (sender_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS comm_announcements (
  id          VARCHAR(64) NOT NULL PRIMARY KEY,
  author_id   VARCHAR(64) NOT NULL,
  author_name VARCHAR(150) NOT NULL DEFAULT '',
  title       VARCHAR(255) NOT NULL DEFAULT '',
  body        TEXT NULL,
  important   TINYINT(1) NOT NULL DEFAULT 0,
  event_id    VARCHAR(64) NULL,
  created_at  DATETIME NULL,
  data        LONGTEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS comm_polls (
  id           VARCHAR(64) NOT NULL PRIMARY KEY,
  creator_id   VARCHAR(64) NOT NULL,
  creator_name VARCHAR(150) NOT NULL DEFAULT '',
  question     VARCHAR(500) NOT NULL DEFAULT '',
  ends_at      DATETIME NULL,
  created_at   DATETIME NULL,
  data         LONGTEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS comm_reports (
  id          VARCHAR(64) NOT NULL PRIMARY KEY,
  message_id  VARCHAR(64) NOT NULL,
  reporter_id VARCHAR(64) NOT NULL,
  reason      VARCHAR(255) NOT NULL DEFAULT '',
  created_at  DATETIME NULL,
  data        LONGTEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS org_profiles (
  user_id    VARCHAR(64) NOT NULL PRIMARY KEY,
  logo_url   VARCHAR(255) NOT NULL DEFAULT '',
  data       LONGTEXT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_kv (
  id         VARCHAR(140) NOT NULL PRIMARY KEY,
  user_id    VARCHAR(64)  NOT NULL,
  k          VARCHAR(60)  NOT NULL,
  value      LONGTEXT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_kv_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS uploads (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    VARCHAR(64) NOT NULL,
  kind       VARCHAR(30) NOT NULL,
  path       VARCHAR(255) NOT NULL,
  mime       VARCHAR(60) NOT NULL,
  size_bytes INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_up_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
