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
        name      => '先制判定',
        fieldName => 'initiative',
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
