use strict;
use utf8;
use open ":utf8";

package palette;

sub chatPaletteFormOptional {
    my %pc = %{shift;};

    require($::core_dir . '/lib/edit.pl');

    $::pc{chatPaletteInsertNum} = ($pc{chatPaletteInsertNum} ||= 2);
    $::pc{paletteStateNum} = ($pc{paletteStateNum} ||= 3);
    $::pc{paletteAttackNum} = ($pc{paletteAttackNum} ||= 3);
    $::pc{paletteMagicNum} = ($pc{paletteMagicNum} ||= 3);
    my $html = <<"HTML";
<div class="box" id="palette-optional">
    <h2>プリセットの追加オプション</h2>
    <div id="palette-common-classes">
        <h3>一般技能の判定の出力設定</h3>
        <p>その行の技能のレベルと、選択したボーナスの組み合わせが追加されます</p>
        <table class="edit-table side-margin">
            <tbody class="highlight-hovered-row">
HTML
    foreach my $i ('TMPL',1 .. $pc{commonClassNum}){
        $html .= '<template id="palette-common-class-template">' if $i eq 'TMPL';
        $html .= '<tr id="palette-common-class-row'.$i.'"><td class="name">'.($pc{"commonClass$i"} =~ s/[(（].+?[）)]$//r).'</td>';
        $html .= '<td class="left">';
        $html .= ::checkbox("paletteCommonClass${i}Dex", '器用度B', 'switchCheckingNameList(this); setChatPalette');
        $html .= ::checkbox("paletteCommonClass${i}Agi", '敏捷度B', 'switchCheckingNameList(this); setChatPalette');
        $html .= ::checkbox("paletteCommonClass${i}Str", '筋力B'  , 'switchCheckingNameList(this); setChatPalette');
        $html .= ::checkbox("paletteCommonClass${i}Vit", '生命力B', 'switchCheckingNameList(this); setChatPalette');
        $html .= ::checkbox("paletteCommonClass${i}Int", '知力B'  , 'switchCheckingNameList(this); setChatPalette');
        $html .= ::checkbox("paletteCommonClass${i}Mnd", '精神力B', 'switchCheckingNameList(this); setChatPalette');
        $html .= '<dl class="checking-names">';
        foreach (['器用度', 'Dex'], ['敏捷度', 'Agi'], ['筋力', 'Str'], ['生命力', 'Vit'], ['知力', 'Int'], ['精神力', 'Mnd']) {
            (my $ja, my $en) = @{$_};
            $html .= <<"HTML";
                <dt data-status="${en}">${ja}Bを参照する判定
                <dd data-status="${en}">
                    @{[ ::input "paletteCommonClass${i}${en}CheckingNames",'text','setChatPalette','placeholder="スペース or カンマ or 読点で区切って判定名を列記"' ]}
HTML
        }
        $html .= '</dl>';
        $html .= '</template>' if $i eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
        </div>
        <details id="palette-insert" @{[ $pc{chatPaletteInsert1} ? 'open' : '' ]}>
          <summary class="header2">追加挿入</summary>
          <ul>
HTML
    foreach ('TMPL',1 .. $pc{chatPaletteInsertNum}){
        $html .= '<template id="palette-insert-template">' if $_ eq 'TMPL';
        $html .= "<li>"
            . ::selectBox("chatPaletteInsert${_}Position", 'setChatPalette', 'def=|<先頭>','general|<非戦闘系の直後>','common|<一般技能の直後>','magic|<魔法系の直後>','attack|<武器攻撃系の直後>','defense|<抵抗回避の直後>')
            . "に挿入"
            . "<textarea name=\"chatPaletteInsert${_}\" onchange=\"setChatPalette()\">$pc{'chatPaletteInsert'.$_}</textarea>";
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </ul>
          <div class="add-del-button"><a onclick="addChatPaletteInsert()">▼</a><a onclick="delChatPaletteInsert()">▲</a></div>
          @{[ ::input "chatPaletteInsertNum","hidden" ]}
        </details>
        <details id="palette-state" @{[ $pc{"paletteState1Name"} ? 'open' : '' ]}>
          <summary class="header2">バフ・デバフの定義</summary>
          <table class="edit-table side-margin">
            <thead>
              <tr>
                <th class="name">名称
                <th class="default-value">デフォルト値
                <th class="target">適用対象
HTML
    require($::core_dir . '/lib/sw2/data-chara-palette.pl');
    foreach ('TMPL', 1 .. $pc{paletteStateNum}) {
        my $i = $_;
        $html .= '<template id="palette-state-template">' if $i eq 'TMPL';
        my $id = $i ne 'TMPL' ? "palette-state-row${i}" : '';
        $html .= <<"HTML";
            <tbody>
              <tr id="${id}">
                <td class="name">
                  @{[ ::input "paletteState${i}Name" ]}
                <td class="default-value">
                  @{[ ::input "paletteState${i}DefaultValue",'number','','placeholder="0"' ]}
                <td class="target">
HTML
        foreach (@data::stateTargets) {
            my %target = %{$_};
            my $targetName = $target{name};
            my $targetFieldName = $target{fieldName};

            $html .= ::checkbox("paletteState${i}Target_${targetFieldName}", $targetName);
        }
        $html .= <<"HTML";
                </td>
              </tr>
            </tbody>
HTML
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addPaletteState()">▼</a><a onclick="delPaletteState()">▲</a></div>
          @{[ ::input 'paletteStateNum','hidden' ]}
        </details>
        <details id="palette-attack" @{[ $pc{"paletteAttack1Name"} ? 'open' : '' ]}>
          <summary class="header2">武器攻撃の追加オプション</summary>
          <p>宣言特技などの名称と修正を入力すると、それにもとづいた命中判定および威力算出の行が追加されます。</p>
          <table class="edit-table side-margin">
            <thead>
              <tr>
                <th>
                <th class="name  ">名称（宣言特技名など）
                <th class="acc   ">命中修正
                <th class="crit  ">C値修正
                <th class="dmg   "><span class="small">ダメージ<br>修正</span>
                <th class="roll  ">出目修正
                <th class="target">対象の武器
            <tbody class="highlight-hovered-row">
HTML
    foreach ('TMPL',1 .. $pc{paletteAttackNum}){
        $html .= '<template id="palette-attack-template">' if $_ eq 'TMPL';
        $html .= '<tr id="palette-attack-row'.$_.'">';
        $html .= '<td class="handle">';
        $html .= '<td>'.::input("paletteAttack${_}Name",'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Acc" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Crit",'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Dmg" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Roll",'','','onchange="setChatPalette()"');
        $html .= '<td class="palette-attack-checklist left">';
        my %added;
        foreach my $num (1 .. $pc{weaponNum}) {
            my $name = $pc{"weapon${num}Name"}.$pc{"weapon${num}Usage"} || '―';
            next if $added{$name};
            $html .= ::checkbox("paletteAttack${_}CheckWeapon${num}",$name,'setChatPalette');
            $added{$name} = 1;
        }
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addPaletteAttack()">▼</a><a onclick="delPaletteAttack()">▲</a></div>
          @{[ ::input "paletteAttackNum","hidden" ]}
        </details>
        <details id="palette-magic" @{[ $pc{"paletteMagic1Name"} ? 'open' : '' ]}>
          <summary class="header2">魔法の追加オプション</summary>
          <p>宣言特技などの名称と修正を入力すると、それにもとづいた、行使判定および威力算出の行が追加されます。</p>
          <table class="edit-table side-margin">
            <thead>
              <tr>
                <th>
                <th class="name ">名称（宣言特技名など）
                <th class="power">魔力修正
                <th class="cast ">行使修正
                <th class="crit ">C値修正
                <th class="dmg  "><span class="small">ダメージ<br>修正</span>
                <th class="target">対象の魔法
            <tbody class="highlight-hovered-row">
HTML
    foreach ('TMPL',1 .. $pc{paletteMagicNum}){
        $html .= '<template id="palette-magic-template">' if $_ eq 'TMPL';
        $html .= '<tr id="palette-magic-row'.$_.'">';
        $html .= '<td class="handle">';
        $html .= '<td>'.::input("paletteMagic${_}Name" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Power",'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Cast" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Crit" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Dmg"  ,'','','onchange="setChatPalette()"');
        $html .= '<td class="palette-magic-checklist left">';
        foreach my $name (@data::class_caster){
            next if (!$data::class{$name}{magic}{jName});
            my $id    = $data::class{$name}{id};
            $html .= ::checkbox("paletteMagic${_}Check$id",$data::class{$name}{magic}{jName},'setChatPalette');
        }
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addPaletteMagic()">▼</a><a onclick="delPaletteMagic()">▲</a></div>
          @{[ ::input "paletteMagicNum","hidden" ]}
        </details>
        <details id="palette-damage">
          <summary class="header2">被ダメージの追加オプション</summary>
          <section class="attributes">
            <h4>属性ごとの増減</h4>
            <dl>
HTML
    require($::core_dir . '/lib/sw2/data-attribute.pl');
    foreach my $attributeName (@data::attributeNames) {
        $html .= <<"HTML";
              <dt data-attribute="${attributeName}">${attributeName}
              <dd data-attribute="${attributeName}">@{[ ::input "paletteDamageOffset$data::attributeFieldNames{$attributeName}",'number','setChatPalette' ]}
HTML
    }
    $html .= <<"HTML";
            </dl>
          </section>
          <section class="taxa">
            <h4>分類ごとの増減</h4>
            <dl>
HTML
    require($::core_dir . '/lib/sw2/data-mons.pl');
    foreach (@data::taxa) {
        (my $taxaJa, my $__, my $__, my $taxaEn) = @{$_};
        next unless $taxaEn;
        $html .= <<"HTML";
              <dt data-taxa="${taxaJa}">${taxaJa}
              <dd data-taxa="${taxaJa}">@{[ ::input "paletteDamageOffset${taxaEn}",'number','setChatPalette' ]}
HTML
    }
    $html .= <<"HTML";
            </dl>
          </section>
        </details>
      </div>
HTML
}

1;
