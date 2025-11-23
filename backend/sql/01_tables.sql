-- 文件表结构
create table files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  path text not null,
  name text not null,
  type text not null, -- image / markdown
  size int,
  created_at timestamp with time zone default now()
);

-- 创建索引以提升查询性能
create index idx_files_user_id on files(user_id);
create index idx_files_created_at on files(created_at desc);
