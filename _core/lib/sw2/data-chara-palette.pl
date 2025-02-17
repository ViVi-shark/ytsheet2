use strict;
use utf8;

package data;

our @stateTargets = (
    {
        name      => '命中力',
        fieldName => 'acc',
    },
    {
        name      => '回避力',
        fieldName => 'eva',
    },
    {
        name      => '防護点',
        fieldName => 'def',
    },
    {
        name      => '生命抵抗力',
        fieldName => 'vitResist',
    },
    {
        name      => '精神抵抗力',
        fieldName => 'mndResist',
    },
    {
        name      => '筋力ボーナス',
        fieldName => 'strB',
    },
    {
        name      => '与物理ダメージ',
        fieldName => 'physicsDamage',
    },
    {
        name      => '与魔法ダメージ',
        fieldName => 'magicDamage',
    },
    {
        name      => '武器攻撃クリティカル値',
        fieldName => 'weaponAttackCritical',
    },
    {
        name      => '魔法クリティカル値',
        fieldName => 'magicCritical',
    },
    {
        name      => '先制判定',
        fieldName => 'initiative',
    },
    {
        name      => '土属性軽減',
        fieldName => 'earthDamageReduction',
    },
    {
        name      => '水・氷属性軽減',
        fieldName => 'waterDamageReduction',
    },
    {
        name      => '炎属性軽減',
        fieldName => 'flameDamageReduction',
    },
    {
        name      => '風属性軽減',
        fieldName => 'windDamageReduction',
    },
    {
        name      => '雷属性軽減',
        fieldName => 'thunderDamageReduction',
    },
    {
        name      => '純エネルギー属性軽減',
        fieldName => 'energyDamageReduction',
    },
    {
        name      => '断空属性軽減',
        fieldName => 'slashDamageReduction',
    },
    {
        name      => '衝撃属性軽減',
        fieldName => 'impactDamageReduction',
    },
    {
        name      => '毒属性軽減',
        fieldName => 'poisonDamageReduction',
    },
    {
        name      => '病気属性軽減',
        fieldName => 'diseaseDamageReduction',
    },
    {
        name      => '精神効果属性軽減',
        fieldName => 'mentalDamageReduction',
    },
    {
        name      => '呪い属性軽減',
        fieldName => 'curseDamageReduction',
    },
);

sub getPaletteStateFieldNames {
    my @fieldNames = ();

    foreach (@stateTargets) {
        my %target = %{$_};
        my $fieldName = $target{fieldName};
        push(@fieldNames, $fieldName);
    }

    return \@fieldNames;
}

sub getPaletteStateFieldNameByTargetName {
    my $targetName = shift;

    foreach (@stateTargets) {
        my %target = %{$_};
        next if $target{name} ne $targetName;
        return $target{fieldName};
    }

    return '';
}

1;
