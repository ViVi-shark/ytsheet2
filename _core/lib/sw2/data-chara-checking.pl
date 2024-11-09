use strict;
use utf8;

package data;

sub checking {
    my $name = shift;
    my $fieldName = shift;
    my $classes = shift;
    my $base = shift;

    my @classNames = ref $classes ? @{$classes} : ($classes);
    my %base = ref $base ? %{$base} : ('' => $base);

    my @formattedBaseValues = ();

    my %classIdTable = ();
    foreach (keys %data::class) {
        my $className = $_;
        my $id = $data::class{$className}{id};
        $classIdTable{$className} = $id;
    }

    my @classIds = ();
    foreach my $className (@classNames) {
        my $baseOfClass = $base{$className} // $base{''};
        my $baseMod = ($baseOfClass =~ s/[-+]\d+$// ? $& : 0);
        my $requiredCraft = ($className =~ s/[＆&](【.+?】)$// ? $1 : undef);
        my $classId = $classIdTable{$className};

        push(
            @formattedBaseValues,
            {
                className     => $className,
                classId       => $classId,
                requiredCraft => $requiredCraft,
                status        => $baseOfClass,
                baseMod       => $baseMod,
            }
        );

        push(@classIds, $classId) if defined($classId);
    }

    return {
        name       => $name,
        fieldName  => $fieldName,
        classNames => \@classNames,
        classIds   => \@classIds,
        baseValues => \@formattedBaseValues,
    };
}

# 判定の定義（五十音順）
# 「魔物知識判定」「先制判定」は専用の項目があるので、とりあつかわない
# 「聞き込み判定」はあらゆる技能でおこなえるので、定義しない
our @checkingList = (
    checking('足跡追跡判定', 'tracking', ['スカウト', 'レンジャー', 'ライダー＆【探索指令】'], '知力'),
    checking('異常感知判定', 'perception', ['スカウト', 'レンジャー', 'ライダー＆【探索指令】'], '知力'),
    checking('隠蔽判定', 'concealment', ['スカウト', 'レンジャー'], '器用度'),
    checking('受け身判定', 'breakFall', ['スカウト', 'レンジャー', 'ライダー'], '敏捷度'),
    checking('応急手当判定', 'firstAid', 'レンジャー', '器用度'),
    checking('隠密判定', 'stealth', ['スカウト', 'レンジャー'], '敏捷度'),
    checking('解除判定', 'release', ['スカウト', 'レンジャー'], '器用度'),
    checking('軽業判定', 'acrobat', ['スカウト', 'レンジャー'], '敏捷度'),
    # checking('聞き込み判定', 'legwork', '任意', '知力'),
    checking('聞き耳判定', 'listening', ['スカウト', 'レンジャー'], '知力'),
    checking('危険感知判定', 'dangerSensing', ['スカウト', 'レンジャー', 'ライダー＆【探索指令】'], '知力'),
    checking('騎乗判定', 'riding', 'ライダー', '敏捷度'),
    checking('見識判定', 'lore', ['セージ', 'アルケミスト', 'バード'], '知力'),
    checking('真偽判定', 'fakePenetration', '冒険者', '知力'),
    checking('水泳判定', 'swimming', '冒険者', '敏捷度'),
    checking('スリ判定', 'pickpocket', 'スカウト', '器用度'),
    checking('生死判定', 'viability', '冒険者', '生命力'),
    # checking(
    #     '先制判定',
    #     'initiative',
    #     ['スカウト', 'ウォーリーダー', 'ウォーリーダー＆【陣率：軍師の知略】'],
    #     {
    #         ''                                 => '敏捷度',
    #         'ウォーリーダー＆【陣率：軍師の知略】' => '知力+1',
    #     }
    # ),
    checking('送還判定', 'demonDeportation', 'デーモンルーラー', '知力'),
    checking('探索判定', 'search', ['スカウト', 'レンジャー', 'ライダー＆【探索指令】', 'ジオマンサー'], '知力'),
    checking('地図作製判定', 'mapping', ['スカウト', 'レンジャー', 'セージ', 'ライダー'], '知力'),
    checking('跳躍判定', 'jump', '冒険者', '敏捷度'),
    checking('天候予測判定', 'weatherForecast', ['スカウト', 'レンジャー', 'ジオマンサー'], '知力'),
    checking(
        '登攀判定',
        'climbing',
        ['スカウト', 'レンジャー', '冒険者'],
        {
            'スカウト'   => '敏捷度',
            'レンジャー' => '敏捷度',
            '冒険者'     => '筋力',
        }
    ),
    checking('尾行判定', 'follow', ['スカウト', 'レンジャー'], '敏捷度'),
    checking('病気知識判定', 'diseaseKnowledge', ['レンジャー', 'セージ'], '知力'),
    checking('文献判定', 'inspectDocuments', ['セージ', 'アルケミスト'], '知力'),
    checking('文明鑑定判定', 'eraIdentify', 'セージ', '知力'),
    checking('変装判定', 'disguise', 'スカウト', '器用度'),
    checking('宝物鑑定判定', 'itemIdentify', ['スカウト', 'セージ'], '知力'),
    # checking('魔物知識判定', 'monsterKnowledge', ['セージ', 'ライダー'], '知力'),
    checking('薬品学判定', 'pharmacy', ['レンジャー', 'セージ', 'アルケミスト'], '知力'),
    checking('罠回避判定', 'trapEvasion', ['スカウト', 'レンジャー', 'ライダー＆【探索指令】'], '知力'),
    checking('罠設置判定', 'trapSetting', ['スカウト', 'レンジャー'], '器用度'),
    checking('腕力判定', 'strength', '冒険者', '筋力'),
);

sub findChecking {
    my %condition = %{shift;};
    $condition{checkingName} .= '判定' if $condition{checkingName} && $condition{checkingName} !~ /判定$/;

    my @result = ();

    foreach (@checkingList) {
        my %checking = %{$_};

        next if $condition{checkingName} && $checking{name} ne $condition{checkingName};

        my @classNames = @{$checking{classNames}};
        next if $condition{className} && !grep {$_ eq $condition{className}} @classNames;

        if ($condition{className} && $condition{status}) {
            my @baseValues = @{$checking{baseValues}};

            my $hit;
            foreach (@baseValues) {
                my %baseValue = %{$_};
                next if $baseValue{className} ne $condition{className};
                next if $baseValue{status} ne $condition{status};
                $hit = 1;
                last;
            }

            next unless $hit;
        }

        push(@result, \%checking);
    }

    return \@result;
}

sub getCheckingFieldName {
    my $checkingName = shift;
    my @found = @{findChecking({ checkingName => $checkingName })};
    my %found = ref $found[0] ? %{$found[0]} : ();
    return $found{fieldName};
}

1;
