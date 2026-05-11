-- 冒险岛文字版 - Supabase 数据库 Schema (无 auth 版本)
-- 在 Supabase Dashboard > SQL Editor 中运行此脚本

-- ========== 玩家存档表 ==========
CREATE TABLE IF NOT EXISTS player_saves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL UNIQUE,
    save_data JSONB NOT NULL DEFAULT '{}',
    equipment_instances TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_player_saves_device_id ON player_saves(device_id);

-- ========== 存档备份表 ==========
CREATE TABLE IF NOT EXISTS player_save_backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    save_data JSONB NOT NULL DEFAULT '{}',
    equipment_instances TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_backups_device_id ON player_save_backups(device_id);
CREATE INDEX IF NOT EXISTS idx_backups_created_at ON player_save_backups(created_at);

-- ========== 自动更新 updated_at ==========
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_player_saves_updated_at ON player_saves;
CREATE TRIGGER update_player_saves_updated_at
    BEFORE UPDATE ON player_saves
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========== 使用说明 ==========
-- 1. 在 Supabase Dashboard 创建项目
-- 2. 进入 Project Settings > API，复制 URL 和 publishable key
-- 3. 在 SQL Editor 中运行此脚本
-- 4. 将 URL 和 key 填入 lib/main.dart
