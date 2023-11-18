-- isu_condition テーブルの condition_text カラムを追加
ALTER TABLE `isu_condition` ADD `condition_text` VARCHAR(255) NOT NULL;

-- isu_condition テーブルの condition カラムを更新
UPDATE
    `isu_condition`
SET condition_text = CASE
                         WHEN `condition` = 'is_dirty=false,is_overweight=false,is_broken=false' THEN 'info'
                         WHEN `condition` = 'is_dirty=true,is_overweight=true,is_broken=true' THEN 'critical'
                         ELSE 'warning' END;