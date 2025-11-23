-- 启用行级安全策略
alter table files enable row level security;

-- 用户只能查看自己的文件
create policy "user_select_own_files" 
on files for select 
to authenticated 
using (auth.uid() = user_id);

-- 用户只能插入自己的文件
create policy "user_insert_own_files" 
on files for insert 
to authenticated 
with check (auth.uid() = user_id);

-- 用户只能删除自己的文件
create policy "user_delete_own_files"
on files for delete
to authenticated
using (auth.uid() = user_id);

-- 用户只能更新自己的文件
create policy "user_update_own_files"
on files for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
