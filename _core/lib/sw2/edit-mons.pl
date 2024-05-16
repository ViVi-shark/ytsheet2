############# フォーム・モンスター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_mons;

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = getSheetData($::in{mode});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = unescapeTags($pc{characterName} || $pc{monsterName} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### 製作者名 --------------------------------------------------
if($mode_make){
  $pc{author} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{protect} = $LOGIN_ID ? 'account' : 'password'; }

if($mode eq 'edit' || ($mode eq 'convert' && $pc{ver})){
  %pc = data_update_mons(\%pc);
}
elsif($mode eq 'blanksheet'){
  $pc{paletteUseBuff} = 1;
  $pc{partsManualInput} = 0;

  %pc = applyCustomizedInitialValues(\%pc, 'm');
}

## カラー
setDefaultColors();

## その他
$pc{partsNum}  ||= 1;
$pc{statusNum} ||= 1;
$pc{lootsNum}  ||= 2;

my $status_text_input = $pc{statusTextInput} || $pc{mount} || 0;

### 改行処理 --------------------------------------------------
$pc{skills}      =~ s/&lt;br&gt;/\n/g;
$pc{description} =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette} =~ s/&lt;br&gt;/\n/g;
$pc{additionalSkills} =~ s/&lt;br&gt;/\n/g;
$pc{additionalDescription} =~ s/&lt;br&gt;/\n/g;
for my $key (keys %pc) {
    $pc{$key} =~ s/&lt;br&gt;/\n/g if $key =~ /^golemReinforcement_[A-Za-z]+_details$/;
}

### フォーム表示 #####################################################################################
my $title;
if ($mode eq 'edit') {
  $title = '編集：';
  if ($pc{characterName}) {
    $title .= $pc{characterName};
    $title .= "（$pc{monsterName}）" if $pc{monsterName};
  }
  else {
    $title .= $pc{monsterName};
  }
}
else {
  $title = '新規作成';
}
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>$title - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/monster.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/sw2/edit-mons.js?${main::ver}" defer></script>
</head>
<body>
  <script src="${main::core_dir}/skin/_common/js/common.js?${main::ver}"></script>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <form id="monster" name="sheet" method="post" action="./" enctype="multipart/form-data" class="@{[ $pc{statusTextInput} ? 'not-calc' : '' ]}">
      <input type="hidden" name="ver" value="${main::ver}">
      <input type="hidden" name="type" value="m">
HTML
if($mode_make){
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>魔物</span><span>データ</span>
          <li onclick="sectionSelect('palette');"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
          <li onclick="sectionSelect('color');" class="color-icon" title="カラーカスタム">
          <li onclick="view('text-rule')" class="help-icon" title="テキスト整形ルール">
          <li onclick="nightModeChange()" class="nightmode-icon" title="ナイトモード切替">
          <li onclick="exportAsJson()" class="download-icon" title="JSON出力">
          <li class="buttons">
            <ul>
              <li @{[ display ($mode eq 'edit') ]} class="view-icon" title="閲覧画面"><a href="./?id=$::in{id}"></a>
              <li @{[ display ($mode eq 'edit') ]} class="copy" onclick="window.open('./?mode=copy&id=$::in{id}@{[  $::in{log}?"&log=$::in{log}":'' ]}');">複製
              <li class="submit" onclick="formSubmit()" title="Ctrl+S">保存
            </ul>
          </li>
        </ul>
        <div id="save-state"></div>
      </div>

      <aside class="message">$message</aside>
      
      <section id="section-common" style="$::commonSectionStyles">
HTML
if($set::user_reqd){
  print <<"HTML";
    <input type="hidden" name="protect" value="account">
    <input type="hidden" name="protectOld" value="$pc{protect}">
    <input type="hidden" name="pass" value="$::in{pass}">
HTML
}
else {
  if($set::registerkey && $mode_make){
    print '登録キー：<input type="text" name="registerkey" required>'."\n";
  }
  print <<"HTML";
      <details class="box" id="edit-protect" @{[$mode eq 'edit' ? '':'open']}>
      <summary>編集保護設定</summary>
      <fieldset id="edit-protect-view"><input type="hidden" name="protectOld" value="$pc{protect}">
HTML
  if($LOGIN_ID){
    print '<input type="radio" name="protect" value="account"'.($pc{protect} eq 'account'?' checked':'').'> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>';
  }
    print '<input type="radio" name="protect" value="password"'.($pc{protect} eq 'password'?' checked':'').'> パスワードで保護 ';
  if ($mode eq 'edit' && $pc{protect} eq 'password') {
    print '<input type="hidden" name="pass" value="'.$::in{pass}.'"><br>';
  } else {
    print '<input type="password" name="pass"><br>';
  }
  print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{protect} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </fieldset>
      </details>
HTML
}
  print <<"HTML";
      <dl class="box" id="hide-options">
        <dt>閲覧可否設定
        <dd id="forbidden-checkbox">
          <select name="forbidden">
            <option value="">内容を全て開示
            <option value="battle" @{[ $pc{forbidden} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿
            <option value="all"    @{[ $pc{forbidden} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿
          </select>
        <dd id="hide-checkbox">
          <select name="hide">
            <option value="">一覧に表示
            <option value="1" @{[ $pc{hide} ? 'selected' : '' ]}>一覧には非表示
          </select>
        <dd>※「一覧に非表示」でもタグ検索結果・マイリストには表示されます
      </dl>
      <div class="box individualization-area">
        @{[ checkbox 'individualization','個別化','individualizationModeChanged' ]}
        @{[ input 'sourceMonsterUrl', 'text', '', 'placeholder="元データＵＲＬ"' ]}
      </div>
      <div class="box in-toc" id="group" data-content-title="分類・タグ">
        <dl>
          <dt>分類</dt>
          <dd>
            <div class="select-input">
              <select name="taxa" oninput="selectInputCheck(this,'その他')">
HTML
foreach (@data::taxa){
  print '<option '.($pc{taxa} eq @$_[0] ? ' selected': '').'>'.@$_[0].'</option>';
}
if($pc{taxa} && !grep { @$_[0] eq $pc{taxa} } @data::taxa){
  print '<option selected>'.$pc{taxa}.'</option>'."\n";
}
$pc{mount} = 0 if !defined($pc{mount});
$pc{golem} = 0 if !defined($pc{golem});
my $mountChecked = $pc{mount} ? 'checked' : '';
my $golemChecked = $pc{golem} ? 'checked' : '';
my $monsterChecked = !($pc{mount} || $pc{golem}) ? 'checked' : '';
print <<"HTML";
              </select>
              <input type="text" name="taxaFree">
              <span data-related-field="taxa"></span>
            </div>
          <dd class="kind">
            <input type="hidden" name="mount" value="$pc{mount}" />
            <input type="hidden" name="golem" value="$pc{golem}" />
            <fieldset>
                <label><input type="radio" name="kind" value="monster" $monsterChecked />魔物</label>
                <label><input type="radio" name="kind" value="mount" $mountChecked />騎獣</label>
                <label><input type="radio" name="kind" value="golem" $golemChecked />ゴーレム</label>
            </fieldset>
            <span class="is-mount individualization-only"></span>
            <span class="is-golem individualization-only"></span>
          <dt class="tag">タグ
          <dd>@{[ input 'tags' ]}
        </dl>
      </div>

      <div class="box in-toc" id="name-form" data-content-title="名称・製作者">
        <div>
          <dl id="character-name">
            <dt>名称
            <dd>@{[ input('monsterName','text',"setName") ]}<span data-related-field="monsterName"></span>
          </dl>
          <dl id="aka">
            <dt>名前
            <dd>@{[ input 'characterName','text','setName','placeholder="※名前を持つ魔物のみ"' ]}
          </dl>
        </div>
        <dl id="player-name">
          <dt>製作者
          <dd>@{[input('author')]}<span data-related-field="author"></span>
          <dt class="individualization-only">個別化データ作者
          <dd class="individualization-only">@{[input('individualizationAuthor')]}
        </dl>
      </div>

      <div class="box status in-toc" data-content-title="基本データ">
        <dl class="mount-only price">
          <dt>価格
          <dd>購入@{[ input 'price' ]}<span data-related-field="price"></span>G
          <dd>レンタル@{[ input 'priceRental' ]}<span data-related-field="priceRental"></span>G
          <dd>部位再生@{[ input 'priceRegenerate' ]}<span data-related-field="priceRegenerate"></span>G
        </dl>
        <dl class="mount-only">
          <dt>適正レベル
          <dd>@{[ input 'lvMin','number','checkMountLevel','min="0"' ]}<span data-related-field="lvMin"></span> ～ @{[ input 'lvMax','number','checkMountLevel','min="0"' ]}<span data-related-field="lvMax"></span>
        </dl>
        <dl class="golem-only">
          <dt>作製可能コンジャラーレベル
          <dd>@{[ input 'requiredConjurerLv','number','','min="0"' ]}<span data-related-field="requiredConjurerLv"></span>
        </dl>
        <dl class="golem-only material">
          <dt>ゴーレム作製素材
          <dd class="material-name"><span class="label">名称</span>@{[ input 'materialName' ]}<span data-related-field="materialName"></span>
          <dd class="normal-price"><input type="radio" name="golemMaterialRank" value="normal" class="individualization-only" @{[$pc{golemMaterialRank} eq 'normal' ? 'checked' : '']} />通常素材<span class="suffix">価格</span>@{[ input 'materialPriceNormal' ]}<span data-related-field="materialPriceNormal"></span>G
          <dd class="higher-price"><input type="radio" name="golemMaterialRank" value="higher" class="individualization-only" @{[$pc{golemMaterialRank} eq 'higher' ? 'checked' : '']} />上級素材<span class="suffix">価格</span>@{[ input 'materialPriceHigher' ]}<span data-related-field="materialPriceHigher"></span>G
        </dl>
        <dl class="level">
          <dt><span class="mount-only">騎獣</span>レベル
          <dd>@{[ input 'lv','number','checkLevel','min="0"' ]}<span data-related-field="lv"></span>
          <dd class="mount-only small">※入力すると、閲覧画面では現在の騎獣レベルのステータスのみ表示されます
        </dl>
        <dl>
          <dt>知能
          <dd>@{[ input 'intellect','','','list="data-intellect"' ]}<span data-related-field="intellect"></span>
        </dl>
        <dl>
          <dt>知覚
          <dd>@{[ input 'perception','','','list="data-perception"' ]}<span data-related-field="perception"></span>
        </dl>
        <dl class="monster-only">
          <dt>反応
          <dd>@{[ input 'disposition','','','list="data-disposition"' ]}<span data-related-field="disposition"></span>
        </dl>
        <dl class="sin omit-if-golem">
          <dt>穢れ
          <dd>@{[ input 'sin','number','','min="0"' ]}<span data-related-field="sin"></span>
          <dd class="offset individualization-only">+@{[ input 'sinOffset','number','','min="0"' ]}
        </dl>
        <dl class="language">
          <dt>言語
          <dd>@{[ input 'language','','','list="data-language"' ]}<span data-related-field="language"></span>
          <dd class="additional individualization-only"><span class="label">追加：</span>@{[ input 'additionalLanguage' ]}
        </dl>
        <dl class="habitat monster-only">
          <dt>生息地
          <dd>@{[ input 'habitat' ]}<span data-related-field="habitat"></span>
          <dd class="replacement individualization-only">
            @{[ checkbox 'habitatReplacementEnabled','置き換え','switchHabitatReplacement' ]}
            @{[ input 'habitatReplacement','','','disabled' ]}
        </dl>
        <dl class="monster-only reputation">
          <dt>知名度／弱点値
          <dd>@{[ input 'reputation' ]}<span data-related-field="reputation"></span>／@{[ input 'reputation+','','','list="list-of-reputation-plus"' ]}<span data-related-field="reputation+"></span>
        </dl>
        <dl class="weakness">
          <dt>弱点
          <dd>@{[ input 'weakness','','','list="data-weakness"' ]}<span data-related-field="weakness"></span>
        </dl>
        <dl class="monster-only">
          <dt>先制値
          <dd>@{[ input 'initiative' ]}<span data-related-field="initiative"></span>
        </dl>
        <dl class="mobility">
          <dt>移動速度<dd>@{[ input 'mobility' ]}
          <dd class="individualization-only">
        </dl>
        <dl class="monster-only vit-resistance">
          <dt>生命抵抗力
          <dd>@{[ input 'vitResist',($status_text_input ? 'text':'number'),'calcVit' ]}<span data-related-field="vitResist"></span> <span class=" calc-only">(@{[ input 'vitResistFix','number','calcVitF' ]}<span data-related-field="vitResistFix"></span>)</span><span class="offset-by-sword-fragment"></span>
        </dl>
        <dl class="monster-only mnd-resistance">
          <dt>精神抵抗力
          <dd>@{[ input 'mndResist',($status_text_input ? 'text':'number'),'calcMnd' ]}<span data-related-field="mndResist"></span> <span class=" calc-only">(@{[ input 'mndResistFix','number','calcMndF' ]}<span data-related-field="mndResistFix"></span>)</span><span class="offset-by-sword-fragment"></span>
        </dl>
      </div>
      <fieldset class="monster-only">@{[ input "statusTextInput",'checkbox','statusTextInputToggle']}命中・回避・抵抗に数値以外を入力</fieldset>
      <div class="box in-toc" data-content-title="攻撃方法・命中・打撃・回避・防護・ＨＰ・ＭＰ">
      <table id="status-table" class="status">
        <thead>
          <tr>
            <th class="lv mount-only">Lv
            <th class="handle">
            <th class="name">攻撃方法<span class="text-part">（部位）</span>
            <th class="acc">命中力
            <th class="atk">打撃点
            <th class="eva">回避力
            <th class="def">防護点
            <th class="hp">ＨＰ
            <th class="mp">ＭＰ
            <th class="vit mount-only">生命抵抗
            <th class="mnd mount-only">精神抵抗
            <th>
          </tr>
        <tbody id="status-tbody">
HTML
foreach my $num (1 .. $pc{statusNum}){
  $pc{"status${num}Damage"} = '2d+' if $pc{"status${num}Damage"} eq '' && $mode eq 'blanksheet';
  print <<"HTML";
        <tr id="status-row${num}">
          <th class="mount-only">
          <td class="handle">
          <td>@{[ input "status${num}Style",'text',"checkStyle(${num}); updatePartsAutomatically()" ]}
          <td>@{[ input "status${num}Accuracy",($status_text_input ? 'text':'number'),"calcAcc($num)" ]}<span class="monster-only calc-only"><br>(@{[ input "status${num}AccuracyFix",'number',"calcAccF($num)" ]})</span>
          <td>@{[ input "status${num}Damage" ]}
          <td>@{[ input "status${num}Evasion",($status_text_input ? 'text':'number'),"calcEva($num)" ]}<span class="monster-only calc-only"><br>(@{[ input "status${num}EvasionFix",'number',"calcEvaF($num)" ]})</span>
          <td>@{[ input "status${num}Defense" ]}
          <td>@{[ input "status${num}Hp" ]}
          <td>@{[ input "status${num}Mp" ]}
          <td class="mount-only">@{[ input "status${num}Vit" ]}
          <td class="mount-only">@{[ input "status${num}Mnd" ]}
          <td><span class="button" onclick="addStatus(${num});">複<br>製</span>
HTML
}
print <<"HTML";
        </tbody>
HTML
foreach my $lv (2 .. ($pc{lvMax}-$pc{lvMin}+1)){
  print <<"HTML";
        <tbody class="mount-only" id="status-tbody${lv}" data-lv="${lv}">
HTML
  foreach my $num (1 .. $pc{statusNum}){
    $pc{"status${num}Damage"} = '2d6+' if $pc{"status${num}Damage"} eq '' && $mode eq 'blanksheet';
    print <<"HTML";
        <tr id="status-row${num}-${lv}">
          <th>
          <td>
          <td class="name" data-style="${num}">$pc{"status${num}Style"}
          <td>@{[ input "status${num}-${lv}Accuracy",($status_text_input ? 'text':'number') ]}
          <td>@{[ input "status${num}-${lv}Damage" ]}
          <td>@{[ input "status${num}-${lv}Evasion",($status_text_input ? 'text':'number') ]}
          <td>@{[ input "status${num}-${lv}Defense" ]}
          <td>@{[ input "status${num}-${lv}Hp" ]}
          <td>@{[ input "status${num}-${lv}Mp" ]}
          <td>@{[ input "status${num}-${lv}Vit" ]}
          <td>@{[ input "status${num}-${lv}Mnd" ]}
          <td>
HTML
  }
  print <<"HTML";
        </tbody>
HTML
}
print <<"HTML";
      </table>
      <div class="add-del-button"><a onclick="addStatus()">▼</a><a onclick="delStatus()">▲</a></div>
      @{[input('statusNum','hidden')]}
      <table class="individualization-only" id="source-status-table">
        <thead>
          <tr>
            <th class="level mount-only">Lv
            <th class="style">攻撃方法（部位）
            <th class="accuracy">命中力
            <th class="damage">打撃点
            <th class="evasion">回避力
            <th class="defense">防護点
            <th class="hp">ＨＰ
            <th class="mp">ＭＰ
            <th class="vit mount-only">生命抵抗
            <th class="mnd mount-only">精神抵抗
        <template id="template-of-part">
          <tr>
            <th class="level mount-only">
            <td class="style">
            <td class="accuracy" data-property-name="accuracy"><span class="base"><span class="value"></span><span class="offset equipment-offset"></span></span><span class="fixed monster-only"><span class="value"></span><span class="offset equipment-offset"></span></span>
            <td class="damage" data-property-name="damage"><span class="value"></span><span class="offset equipment-offset"></span>
            <td class="evasion" data-property-name="evasion"><span class="base"><span class="value"></span><span class="offset equipment-offset"></span></span><span class="fixed monster-only"><span class="value"></span><span class="offset equipment-offset"></span></span>
            <td class="defense" data-property-name="defense"><span class="value"></span><span class="offset equipment-offset"></span>
            <td class="hp" data-property-name="hp"><span class="value"></span><span class="offset hp-option-offset"></span><span class="offset equipment-offset"></span>
            <td class="mp" data-property-name="mp"><span class="value"></span><span class="offset equipment-offset"></span>
            <td class="vit mount-only">
            <td class="mnd mount-only">
        </template>
      </table>
        <fieldset class="mount-only individualization-only mount-hp-options">
          @{[ checkbox 'exclusiveMount','専有','mountHpOptionsUpdated','data-hp="10"' ]}
          @{[ checkbox 'ridingHpReinforcement','【ＨＰ強化】','mountHpOptionsUpdated','data-hp="5"' ]}
          @{[ checkbox 'ridingHpReinforcementSuper','【ＨＰ超強化】','mountHpOptionsUpdated','data-hp="5"' ]}
        </fieldset>
      </div>
      <fieldset class="box parts in-toc" data-content-title="部位数・コア部位">
        @{[ checkbox 'partsManualInput', '部位数と内訳を手動入力する', 'updatePartsAutomatically' ]}
        <dl><dt>部位数<dd>@{[ input 'partsNum','number','updatePartList','min="1"' ]}<span data-related-field="partsNum"></span> (@{[ input 'parts','','updatePartList' ]}<span data-related-field="parts"></span>) </dl>
        <dl><dt>コア部位<dd>@{[ input 'coreParts','','','list="list-of-core-part"' ]}<span data-related-field="coreParts"></span></dl>
        <datalist id="list-of-core-part"></datalist>
      </fieldset>
      <fieldset class="box monster-only individualization-only sword-fragment-box">
        <h2>剣のかけら</h2>
        <label class="num">
            個数
            @{[ input 'swordFragmentNum','number','','min="0"' ]}
            <span class="effect-summary">
                <span class="hp-offset">ＨＰ<i class="value"></i></span>
                <span class="mp-offset">ＭＰ<i class="value"></i></span>
                <span class="vit-resistance-offset">生命抵抗力<i class="value"></i></span>
                <span class="mnd-resistance-offset">精神抵抗力<i class="value"></i></span>
            </span>
        </label>
        <table class="offset-distribution">
            <thead>
                <tr>
                    <th class="part-name" rowspan="2">部位
                    <th colspan="3">ＨＰ
                    <th colspan="3">ＭＰ
                <tr>
                    <th class="base">基本値
                    <th class="offset">かけら<br />補正
                    <th class="total">小計
                    <th class="base">基本値
                    <th class="offset">かけら<br />補正
                    <th class="total">小計
            <tbody>
            <tfoot class="sum">
                <tr>
                    <th>全部位合計
                    <td class="base">
                    <td class="hp offset">
                    <td class="total">
                    <td class="base">
                    <td class="mp offset">
                    <td class="total">
        </table>
        <template id="template-of-sword-fragment-offset-distribution-row">
            <tr>
                <td class="part-name">
                <td class="hp base">
                <td class="hp offset">+<input type="number" min="0" />=
                <td class="hp total">
                <td class="mp base">
                <td class="mp offset">+<input type="number" min="0" />=
                <td class="mp total">
        </template>
      </fieldset>
      <fieldset class="box mount-only individualization-only mount-equipments">
        <h2>騎獣用武装</h2>
        <dl class="parts"></dl>
        <template id="template-of-mount-equipment-part">
          <dt class="part">
          <dd class="part">
              <dl class="equipments">
                  <dt class="weapon">武器
                  <dd class="weapon" data-name-group="weapon">
                      <dl class="weapon-settings">
                          <dt class="name">名称
                          <dd class="name"><input type="text" data-property-name="name" />
                          <dt class="accuracy">命中力判定
                          <dd class="accuracy"><input type="number" data-property-name="accuracy" />
                          <dt class="damage">打撃点
                          <dd class="damage"><input type="number" data-property-name="damage" />
                      </dl>
                  </dd>
                  <dt class="armor">防具
                  <dd class="armor" data-name-group="armor">
                      <dl class="armor-settings">
                          <dt class="name">名称
                          <dd class="name"><input type="text" data-property-name="name" />
                          <dt class="evasion">回避力判定
                          <dd class="evasion"><input type="number" data-property-name="evasion" />
                          <dt class="defense">防護点
                          <dd class="defense"><input type="number" data-property-name="defense" />
                          <dt class="hp">最大ＨＰ
                          <dd class="hp"><input type="number" data-property-name="hp" />
                          <dt class="mp">最大ＭＰ
                          <dd class="mp"><input type="number" data-property-name="mp" />
                      </dl>
                  </dd>
              </dl>
          </dd>
        </template>
      </fieldset>
      <div class="box skills">
        <h2 class="in-toc">特殊能力</h2>
        <fieldset class="riding-checks individualization-only">
          @{[ checkbox 'ridingMagicIndication','【魔法指示】' ]}
          @{[ checkbox 'ridingUnlockSpecialSkills','【特殊能力解放】' ]}
          @{[ checkbox 'ridingUnlockSpecialSkillsFully','【特殊能力完全解放】' ]}
        </fieldset>
        <textarea name="skills">$pc{skills}</textarea>
        <div class="annotate">
          <b>行頭に</b>特殊能力の分類マークなどを記述すると、そこから次の「改行」または「全角スペース」までを自動的に見出し化します。<br>
           2.0での分類マークでも構いません。また、入力簡易化の為に入力しやすい代替文字での入力も可能です。<br>
           以下に見出しとして変換される記号・文字列を一覧にしています。<br>
          部位見出し（●）：<code>●</code><br>
          常時型　　（<i class="s-icon passive"></i>）：<code>[常]</code><code>○</code> <code>◯</code> <code>〇</code><br>
HTML
if($::SW2_0){
print <<"HTML";
          主動作型　（<i class="s-icon major0"   ></i>）：<code>[主]</code><code>＞</code> <code>▶</code> <code>〆</code><br>
          補助動作型（<i class="s-icon minor0"   ></i>）：<code>[補]</code><code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
          宣言型　　（<i class="s-icon active0"  ></i>）：<code>[宣]</code><code>🗨</code> <code>□</code> <code>☑</code><br>
          条件型　　（<i class="s-icon condition"></i>）：<code>[条]</code><code>▽</code><br>
          条件選択型（<i class="s-icon selection"></i>）：<code>[選]</code><code>▼</code><br>
HTML
} else {
print <<"HTML";
          戦闘準備型（<i class="s-icon setup"  ></i>）：<code>[準]</code><code>△</code><br>
          主動作型　（<i class="s-icon major"  ></i>）：<code>[主]</code><code>＞</code> <code>▶</code> <code>〆</code><br>
          補助動作型（<i class="s-icon minor"  ></i>）：<code>[補]</code><code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
          宣言型　　（<i class="s-icon active" ></i>）：<code>[宣]</code><code>🗨</code> <code>□</code> <code>☑</code><br>
HTML
}
my $reinforcementItemGrade_S_state = $pc{reinforcementItemGrade} eq '小' ? 'selected' : '';
my $reinforcementItemGrade_M_state = $pc{reinforcementItemGrade} eq '中' ? 'selected' : '';
my $reinforcementItemGrade_L_state = $pc{reinforcementItemGrade} eq '大' ? 'selected' : '';
my $reinforcementItemGrade_XL_state = $pc{reinforcementItemGrade} eq '極大' ? 'selected' : '';
print <<"HTML";
          <code>[]</code>で漢字一文字を囲う記法は、行頭でなくても各マークに変換されます。
        </div>
        <div data-related-field="skills"></div>
      </div>
      <div class="box additional-skills individualization-only monster-only">
        <h2>追加特殊能力</h2>
        <textarea name="additionalSkills">$pc{additionalSkills}</textarea>
      </div>
      <div class="box reinforcement-items golem-only">
        <h2>ゴーレム強化アイテム</h2>
        <label class="max-count">最大数@{[input('reinforcementItemMaxCount','number','','min="0"')]}</label>
        <label class="grade">
            グレード
            <select name="reinforcementItemGrade" oninput="updateGolemReinforcementItemGrade();">
                <option>
                <option $reinforcementItemGrade_S_state>小
                <option $reinforcementItemGrade_M_state>中
                <option $reinforcementItemGrade_L_state>大
HTML
print "<option $reinforcementItemGrade_XL_state>極大" if $::SW2_0;
print <<"HTML";
            </select>
        </label>
        <dl class="items">
HTML
my @golemReinforcementItems = data::getGolemReinforcementItems($::SW2_0 ? '2.0' : '2.5');
for my $itemAddress (@golemReinforcementItems) {
    my %item = %{$itemAddress};
    print "\n";
    if ($item{prerequisiteItem}) {
        print "<dt class=\"item\" data-prerequisite-item=\"$item{prerequisiteItem}\">";
    } else {
        print '<dt class="item">'
    }
    my $checkState = $pc{"golemReinforcement_$item{fieldName}_supported"} ? 'checked' : '';
    print "<label><input type=\"checkbox\" name=\"golemReinforcement_$item{fieldName}_supported\" $checkState />$item{name}</label>";
    print "\n";
    print "<dd class=\"item @{[$checkState eq 'checked' ? 'supported' : '']}\" data-item-name=\"$item{name}\" data-field-name=\"$item{fieldName}\"><dl class=\"item\">";
    my %abilitySuffixes = $item{abilitySuffixes} ? %{$item{abilitySuffixes}} : ();
    print "<dt class=\"ability\">能力<dd class=\"ability\" data-suffixes=\"$abilitySuffixes{'小'}|$abilitySuffixes{'中'}|$abilitySuffixes{'大'}|$abilitySuffixes{'極大'}\">$item{ability}";
    my %prices = %{$item{prices}};
    print "<dt class=\"price\">価格<dd class=\"price\"><input type=\"number\" name=\"golemReinforcement_$item{fieldName}_price\" data-prices=\"$prices{'小'}|$prices{'中'}|$prices{'大'}|$prices{'極大'}\" />";
    print "<span data-related-field=\"golemReinforcement_$item{fieldName}_price\"></span>";
    print 'G';
    print "<dt class=\"part-restriction\">部位制限<dd class=\"part-restriction\">";
    if ($item{requirementAllParts}) {
        print '<span class="requirement-all-parts">全部位必須</span>';
    } else {
        my $value = escapeHTML($pc{"golemReinforcement_$item{fieldName}_partRestriction"});
        print "<input type=\"text\" name=\"golemReinforcement_$item{fieldName}_partRestriction\" value=\"$value\" list=\"golem-reinforcement-item-part-restriction-list\" />";
        print "<span data-related-field=\"golemReinforcement_$item{fieldName}_partRestriction\"></span>";
    }
    if ($item{additionalField}) {
        print "<dt class=\"additional-field\" data-kind=\"$item{additionalField}\">$item{additionalField}";
        print "<dd class=\"additional-field\" data-kind=\"$item{additionalField}\">";
        if ($item{additionalField} eq '詳細') {
            my $value = escapeHTML($pc{"golemReinforcement_$item{fieldName}_details"});
            print "<textarea name=\"golemReinforcement_$item{fieldName}_details\">$value</textarea>";
            print "<div data-related-field=\"golemReinforcement_$item{fieldName}_details\"></div>";
        } elsif ($item{additionalField} eq '打撃点') {
            my $value = escapeHTML($pc{"golemReinforcement_$item{fieldName}_damageOffset"});
            print "+<input type=\"number\" name=\"golemReinforcement_$item{fieldName}_damageOffset\" value=\"$value\" />";
            print "<span data-related-field=\"golemReinforcement_$item{fieldName}_damageOffset\"></span>";
        } elsif ($item{additionalField} eq '地上移動速度') {
            my $value = escapeHTML($pc{"golemReinforcement_$item{fieldName}_landMobility"});
            print "<input type=\"text\" name=\"golemReinforcement_$item{fieldName}_landMobility\" value=\"$value\" />";
            print "<span data-related-field=\"golemReinforcement_$item{fieldName}_landMobility\"></span>";
        }
    }
    print "\n";
    print '</dl>';
}
print <<"HTML";
        </dl>
        <datalist id="golem-reinforcement-item-part-restriction-list"></datalist>
        <section class="using-items"></section>
        <template id="template-of-part-restriction-group">
            <section class="part-restriction-group">
                <h4 class="part-restriction"><span class="text"></span><i class="count"><span class="current"></span><span class="max"></span></i></h4>
                <ul class="using-items"></ul>
            </section>
        </template>
        <template id="template-of-using-item">
            <li class="using-item">
                <label>
                    <input type="checkbox" class="to-use" />
                    <h5 class="name-area">
                        <span class="item-name"></span>
                        <span class="item-grade"></span>
                        <span class="item-price"></span>
                    </h5>
                    <div class="ability-outline">
                        <span class="ability-name"></span>
                    </div>
                    <div class="ability-details"></div>
                </label>
            </li>
        </template>
      </div>
      <fieldset class="box loots monster-only">
        <h2 class="in-toc" data-content-title="戦利品">戦利品@{[ checkbox 'disableLoots','戦利品をもたない','switchLoots' ]}</h2>
        <div id="loots-list" class="loots-list">
          <ul id="loots-num">
HTML
foreach my $num (1 .. $pc{lootsNum}){ print "<li id='loots-num${num}'><span class='handle'></span>".input("loots${num}Num",'','','list="data-roots-num"'); }
print <<"HTML";
          </ul>
          <ul id="loots-item">
HTML
foreach my $num (1 .. $pc{lootsNum}){ print "<li id='loots-item${num}'><span class='handle'></span>".input("loots${num}Item"); }
print <<"HTML";
        </ul>
      </div>
      <div class="add-del-button"><a onclick="addLoots()">▼</a><a onclick="delLoots()">▲</a></div>
      @{[input('lootsNum','hidden')]}
      <dl class="" id="source-loot-table"></dl>
      <template id="template-of-source-loot-table-row">
          <dt class="range">
          <dd class="content">
      </template>
      <div class="additional-loots individualization-only monster-only">
        <h2>追加戦利品</h2>
        <div class="loots-list">
          <ul id="additional-loots-item">
HTML
$pc{additionalLootsNum} ||= 1;
foreach my $num (1 .. $pc{additionalLootsNum}){ print "<li id='additional-loots-item${num}'><span class='handle'></span>".input("additionalLoots${num}Item"); }
print <<"HTML";
          </ul>
          <template id="template-of-additional-loot">
            <li><span class='handle'></span><input type="text" />
          </template>
        </div>
        <div class="add-del-button"><a onclick="addAdditionalLoots()">▼</a><a onclick="delAdditionalLoots()">▲</a></div>
        @{[input('additionalLootsNum','hidden')]}
      </div>
      </fieldset>
      <div class="box description">
        <h2 class="in-toc">解説</h2>
        <textarea name="description">$pc{description}</textarea>
        <div data-related-field="description"></div>
        <h2 class="individualization-only">追加解説</h2>
        <textarea name="additionalDescription" class="individualization-only">$pc{additionalDescription}</textarea>
      </div>
      </section>
      
      @{[ chatPaletteForm ]}
      
      @{[ colorCostomForm ]}
    
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
    @{[ deleteForm($mode) ]}
HTML
if ($mode eq 'edit') {
}
print "<fieldset id=\"loaded-data\" style=\"display: none;\">\n";
for my $key (keys %pc) {
    next if $key !~ /^partEquipment\d|^golemReinforcement_(?:[A-Za-z]+_part(?:\d+|All)_using|quartzDisruption_attribute)$|^swordFragment_[hm]pOffset_part\d+$/;
    print "<input type=\"hidden\" name=\"$key\" value=\"$pc{$key}\" />\n";
}
print "</fieldset>\n";
print <<"HTML";
    </article>
HTML
# ヘルプ
print textRuleArea( '','「特殊能力」「解説」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">(C)Group SNE「ソード・ワールド2.0／2.5」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="data-intellect">
    <option value="なし">
    <option value="動物並み">
    <option value="低い">
    <option value="人間並み">
    <option value="高い">
    <option value="命令を聞く">
  </datalist>
  <datalist id="data-perception">
    <option value="五感">
    <option value="五感（暗視）">
    <option value="五感（）">
    <option value="魔法">
    <option value="機械">
  </datalist>
  <datalist id="data-disposition">
    <option value="友好的">
    <option value="中立">
    <option value="敵対的">
    <option value="腹具合による">
    <option value="命令による">
  </datalist>
  <datalist id="data-language">
    <option value="なし">
  </datalist>
  <datalist id="list-of-reputation-plus">
    <option>―</option>
  </datalist>
  <datalist id="data-weakness">
    <option value="命中力+1">
    <option value="物理ダメージ+2点">
    <option value="魔法ダメージ+2点">
    <option value="属性ダメージ+3点">
    <option value="回復効果ダメージ+3点">
    <option value="なし">
  </datalist>
  <datalist id="data-roots-num">
    <option value="自動">
  </datalist>
  <script>
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;
