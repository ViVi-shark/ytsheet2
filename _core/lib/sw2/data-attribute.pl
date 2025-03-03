use strict;
use utf8;

package data;

our @attributeNames = ('炎', '水・氷', '風', '土', '雷', '衝撃', '断空', '純エネルギー', '毒', '病気', '呪い', '精神効果');

our %attributeFieldNames = (
    '炎'           => 'Flame',
    '水・氷'       => 'Water',
    '風'           => 'Wind',
    '土'           => 'Earth',
    '雷'           => 'Thunder',
    '衝撃'         => 'Impact',
    '断空'         => 'Slash',
    '純エネルギー' => 'Energy',
    '毒'           => 'Poison',
    '病気'         => 'Disease',
    '呪い'         => 'Curse',
    '精神効果'     => 'Mental',
);

1;
