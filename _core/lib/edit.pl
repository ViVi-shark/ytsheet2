################## 更新フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use Encode;

our $LOGIN_ID = check;

our %in;
for (param()){ $in{$_} = param($_); }

our $mode = $in{'mode'};

if($set::user_reqd && !check){ error('ログインしていません。'); }
### 個別処理 --------------------------------------------------
my $type = param('type');
our %conv_data = ();
if(param('url')){
  require $set::lib_convert;
  %conv_data = data_convert(param('url'));
  $type = $conv_data{'type'};
}

if   ($type eq 'm'){ require $set::lib_edit_mons; }
elsif($type eq 'i'){ require $set::lib_edit_item; }
else               { require $set::lib_edit_char; }

### 共通サブルーチン --------------------------------------------------
## データ読み込み
sub pcDataGet {
  my $mode = shift;
  my %pc;
  my $file;
  my $message;
  my $datadir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : $set::char_dir;
  # 新規作成エラー
  if($main::make_error) {
    $mode = 'blanksheet';
    for (param()){ $pc{$_} = param($_); }
    $message = $::make_error;
  }
  # 保存
  if($mode eq 'save'){
    $message .= 'データを更新しました。<a href="./?id='.$::in{'id'}.'">⇒シートを確認する</a>';
    $mode = 'edit';
  }
  # 編集 / 複製 / コンバート
  if($mode eq 'edit'){
    (undef, undef, $file, undef) = getfile($in{'id'},$in{'pass'},$LOGIN_ID);
    my $datafile = $in{'backup'} ? "${datadir}${file}/backup/$in{'backup'}.cgi" : "${datadir}${file}/data.cgi";
    open my $IN, '<', $datafile or &login_error;
    $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
    close($IN);
    if($in{'backup'}){
      $pc{'protect'} = protectTypeGet("${datadir}${file}/data.cgi");
      $message = $pc{'updateTime'}.' 時点のバックアップデータから編集しています。';
    }
  }
  elsif($mode eq 'copy'){
    $file = (getfile_open($in{'id'}))[0];
    my $datafile = $in{'backup'} ? "${datadir}${file}/backup/$in{'backup'}.cgi" : "${datadir}${file}/data.cgi";
    open my $IN, '<', $datafile or error 'データがありません。';
    $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
    close($IN);

    delete $pc{'image'};
    $pc{'protect'} = 'password';

    $message  = '「<a href="./?id='.$in{'id'}.'" target="_blank"><!NAME></a>」';
    $message .= 'の<br><a href="./?id='.$in{'id'}.'&backup='.$in{'backup'}.'" target="_blank">'.$pc{'updateTime'}.'</a> 時点のバックアップデータ' if $in{'backup'};
    $message .= 'を<br>コピーして新規作成します。<br>（まだ保存はされていません）';
  }
  elsif($mode eq 'convert'){
    %pc = %::conv_data;
    delete $pc{'image'};
    $pc{'protect'} = 'password';
    $message = '「<a href="'.param('url').'" target="_blank"><!NAME></a>」をコンバートして新規作成します。<br>（まだ保存はされていません）';
  }
  return (\%pc, $mode, $file, $message)
}
## トークン生成
sub token_make {
  my $token = random_id(12);

  my $mask = umask 0;
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH $token."<>".(time + 60*60*24*7)."<>\n";
  close($FH);
  
  return $token;
}

## ログインエラー
sub login_error {
  our $login_error = 'パスワードが間違っているか、<br>編集権限がありません。';
  require $set::lib_view;
  exit;
}

## 画像欄
sub image_form {
  return <<"HTML";
    <div class="box" id="image" style="max-height:550px;">
      <h2>キャラクター画像</h2>
      <p>
        <input type="file" accept="image/*" name="imageFile" onchange="imagePreView(this.files[0])"><br>
        ※ @{[ int($set::image_maxsize / 1024) ]}KBまでのJPG/PNG/GIF
      </p>
      <p>
        <a class="button" onclick="imagePositionView()">画像表示のプレビュー／カスタマイズ</a>
      </p>
      <p>
      画像の注釈（作者や権利表記など）
      @{[ input 'imageCopyright' ]}
      </p>
      <p>
        <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
        @{[input('image','hidden')]}
      </p>
      <h2>セリフ</h2>
      <p class="words-input">
      @{[ input 'words' ]}<br>
      セリフの配置：
      <select name="wordsX">@{[ option 'wordsX','右','左' ]}</select>
      <select name="wordsY">@{[ option 'wordsY','上','下' ]}</select>
      </p>
    </div>
    @{[ input('imageUpdate', 'hidden') ]}
    
    <div id="image-custom" style="display:none">
      <div class="image-custom-view-area">
        <div id="image-custom-frame-L" class="image-custom-frame"><div class="image-custom-view"
 class="image-custom-view"><b>横幅が狭い時</b></div></div>
        <div id="image-custom-frame-C" class="image-custom-frame"><div class="image-custom-view"
 class="image-custom-view"><b>標準の比率　<small>※縦横比は適宜変動します</small></b></div>
          @{[ input "imagePositionY",'range','imagePosition','' ]}
          @{[ input "imagePositionX",'range','imagePosition','' ]}
        </div>
        <div id="image-custom-frame-R" class="image-custom-frame"><div class="image-custom-view"
 class="image-custom-view"><b>縦幅が狭い時</b></div></div>
      </div>
      <div class="image-custom-form">
        <p>
          縦基準位置:<span id="image-positionY-view"></span> ／
          横基準位置:<span id="image-positionX-view"></span><br>
        </p>
        <p>
          表示（トリミング）方式：<br><select name="imageFit" oninput="imagePosition()">
          <option value="cover"   @{[$::pc{'imageFit'} eq 'cover'  ?'selected':'']}>自動的に最低限のトリミング（表示域いっぱいに表示）
          <option value="contain" @{[$::pc{'imageFit'} eq 'contain'?'selected':'']}>トリミングしない（必ず画像全体を収める）
          <option value="percentX" @{[$::pc{'imageFit'} eq 'percentX'?'selected':'']}>任意のトリミング／横幅を基準
          <option value="percentY" @{[$::pc{'imageFit'} eq 'percentY'?'selected':'']}>任意のトリミング／縦幅を基準
          <option value="unset"   @{[$::pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大縮小せず表示（ドット絵など向き）
          </select><br>
          <small>※いずれの設定でも、クリックすると画像全体が表示されます。</small>
        </p>
        <p id="image-percent-config">
          拡大率：@{[ input "imagePercent",'number','imagePosition','style="width:4em;"' ]}%<br>
          <input type="range" id="image-percent-bar" min="10" max="1000" oninput="imagePercentBarChange(this.value)" style="width:100%;"><br>
          （100%で幅ピッタリ）<br>
        </p>
        <p class="center"><a class="button" onclick="imagePositionClose()">画像表示のプレビューを閉じる</a><p>
      </div>
    </div>
HTML
}

## 簡略化系
sub input {
  my ($name, $type, $oniput, $other) = @_;
  if($oniput && $oniput !~ /\(.*?\)$/){ $oniput .= '()'; }
  '<input'.
  ' type="'.($type?$type:'text').'"'.
  ' name="'.$name.'"'.
  ' value="'.($_[1] eq 'checkbox' ? 1 : $::pc{$name}).'"'.
  ($other?" $other":"").
  ($type eq 'checkbox' && $::pc{$name}?" checked":"").
  ($oniput?' oninput="'.$oniput.'"':"").
  '>';
}
sub option {
  my $name = shift;
  my $text = '<option value="">';
  foreach my $i (@_) {
    my $value = $i;
    my $view;
    if($value =~ s/\|\<(.*?)\>$//){ $view = $1 } else { $view = $value }
    $text .= '<option value="'.$value.'"'.($::pc{$name} eq $value ? ' selected':'').'>'.$view
  }
  return $text;
}
sub display {
  $_[0] ? ($_[1] ? " style=\"display:$_[1]\"" : '') : ' style="display:none"'
}

1;