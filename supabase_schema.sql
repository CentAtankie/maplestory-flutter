-- 冒险岛文字版 - Supabase 数据库 Schema
-- 在 Supabase Dashboard > SQL Editor 中运行此脚本

-- ========== 玩家存档表 ==========
CREATE TABLE IF NOT EXISTS player_saves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    save_data JSONB NOT NULL DEFAULT '{}',
    equipment_instances TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

-- 为 user_id 创建索引，加速查询
CREATE INDEX IF NOT EXISTS idx_player_saves_user_id ON player_saves(user_id);

-- ========== 存档备份表（保留最近 5 份） ==========
CREATE TABLE IF NOT EXISTS player_save_backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    save_data JSONB NOT NULL DEFAULT '{}',
    equipment_instances TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_backups_user_id ON player_save_backups(user_id);
CREATE INDEX IF NOT EXISTS idx_backups_created_at ON player_save_backups(created_at);

-- ========== 行级安全（RLS）策略 ==========
-- 启用 RLS
ALTER TABLE player_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_save_backups ENABLE ROW LEVEL SECURITY;

-- 玩家只能访问自己的存档
CREATE POLICY "Users can only access own saves"
    ON player_saves
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 玩家只能访问自己的备份
CREATE POLICY "Users can only access own backups"
    ON player_save_backups
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

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
-- 2. 进入 Project Settings > API，复制 URL 和 anon/public key
-- 3. 进入 Authentication > Providers，启用 "Anonymous Sign-ins"（或保持默认密码注册）
-- 4. 在 SQL Editor 中运行此脚本
-- 5. 将 URL 和 anon key 填入 lib/main.dart 中的 Supabase.initialize
