// 開閉系 ----------------------------------------
function popImage(id) {
  if(typeof images !== 'undefined'){
    id ||= 1;
    document.getElementById('image-box-image').src = images[id];
  }
  document.getElementById("image-box").style.bottom = 0;
  document.getElementById("image-box").style.opacity = 1;

}
function closeImage() {
  document.getElementById("image-box").style.opacity = 0;
  setTimeout(function(){
    document.getElementById("image-box").style.bottom = '-100vh';
  },200);
}
function closeTextareaForCopy() {
  document.getElementById('copyText-box').remove();
  document.getElementById('copyText-box-textarea').remove();
}
function popTextareaForCopy(text) {
  const div = document.createElement('div');
  div.id = 'copyText-box';
  div.onclick = closeTextareaForCopy;

  const textarea = document.createElement('textarea');
  textarea.id = 'copyText-box-textarea';
  textarea.value = text;

  document.getElementsByTagName('main')[0].appendChild(div);
  document.getElementsByTagName('main')[0].appendChild(textarea);

  textarea.focus();
  textarea.setSelectionRange(0, textarea.value.length);
}
function editOn() {
  document.querySelectorAll('.float-box:not(#login-form)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("login-form").classList.toggle('show');
}
function loglistOn() {
  document.querySelectorAll('.float-box:not(#loglist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("loglist").classList.toggle('show');
}
function downloadListOn() {
  document.querySelectorAll('.float-box:not(#downloadlist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("downloadlist").classList.toggle('show');
}
let cpOpenFirst = 0;
function chatPaletteOn() {
  document.querySelectorAll('.float-box:not(.chat-palette)').forEach(obj => { obj.classList.remove('show') });
  document.querySelector(".chat-palette").classList.toggle('show');
  if(!cpOpenFirst){ chatPaletteSelect(paletteTool); }
  cpOpenFirst++;
}
function chatPaletteSelect(tool) {
  const url =
      document.querySelector('head link[rel="ytchat-palette-exporting-point"][href]').getAttribute('href') + '&tool=' + tool;

  fetch(url)
  .then(response => { return response.text(); })
  .then(text => { document.getElementById('chatPaletteBox').value = text; });
  document.querySelectorAll('.chat-palette-menu a').forEach(elm => {
    elm.classList.remove('check');
  });
  document.getElementById('cp-switch-'+(tool||'ytc')).classList.add('check');
}

// スクロール位置 ----------------------------------------
window.addEventListener('DOMContentLoaded', ()=>{
  document.querySelector('.header-back-name').addEventListener('click', ()=>{
    window.scroll({
      top: 0,
      behavior: "smooth",
    });
  })
});

// 保存系 ----------------------------------------
function getJsonData(targetEnvironment = '') {
  const paramId = /id=[0-9a-zA-Z\-]+/.exec(location.href)[0];
  return new Promise((resolve, reject)=>{
    let xhr = new XMLHttpRequest();
    xhr.open('GET', `./?${paramId}&mode=json&target=${targetEnvironment}`, true);
    xhr.responseType = "json";
    xhr.onload = (e) => {
      resolve(e.currentTarget.response);
    };
    xhr.onerror = () => reject('error');
    xhr.onabort = () => reject('abort');
    xhr.ontimeout = () => reject('timeout');
    xhr.send();
  });
}

function generateUdonariumZipFile(title, data, image){
  return new Promise((resolve, dummy)=>{
    let zip = new JSZip();
    let folder = zip.folder(title);
    if(image.hash) {
      folder.file(image.fileName, image.data);
    }
    folder.file(`${title}.xml`, data, {binary: false});
    zip.generateAsync({ type: "blob" }).then(blob => {
      const dataUrl = URL.createObjectURL(blob);
      resolve(dataUrl);
    });
  });
}

function downloadFile(title, url) {
  const a = document.createElement("a");
  document.body.appendChild(a);
  a.download = title;
  a.href = url;
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function copyToClipboard(text) {
  // navigator.clipboard.writeText(text); は許可されていなければ動作せず、
  // 非 SSL で繋いでいる場合は許可することすらできないので利用できない。
  const textarea = document.createElement('textarea');
  document.getElementById('downloadlist').appendChild(textarea);
  textarea.value = text;
  textarea.focus();
  textarea.setSelectionRange(0, textarea.value.length);
  const isCopied = document.execCommand('copy');
  textarea.remove();
  if (isCopied) {
    return;
  } else{
    throw 'クリップボードへのコピーに失敗しました';
  }
}

async function downloadAsUdonarium() {
  const characterDataJson = await getJsonData('udonarium');
  const characterId = characterDataJson.characterName || characterDataJson.monsterName || characterDataJson.aka || '無題';
  const image = await output.getPicture(characterDataJson.imageURL || defaultImage, "image."+characterDataJson.image);
  const udonariumXml = output.generateUdonariumXml(generateType, characterDataJson, location.href, image.hash);
  const udonariumUrl = await generateUdonariumZipFile((characterDataJson.characterName||characterDataJson.aka), udonariumXml, image);
  downloadFile(`udonarium_data_${characterId}.zip`, udonariumUrl);
}

function getCcfoliaJson() {
  return new Promise((resolve, reject)=>{
    getJsonData('ccfolia').then((characterDataJson)=>{
      output.generateCcfoliaJson(generateType,characterDataJson, location.href).then(resolve, reject);
    }, reject);
  });
}

function getClipboardItem() {
  try {
    return new ClipboardItem({
      'text/plain': getCcfoliaJson().then((json)=>{
        return new Promise(async (resolve)=>{
          resolve(new Blob([json]));
        });
      }, (err)=>{
        console.error(err);
        alert('キャラクターシートのデータ取得に失敗しました。通信状況等をご確認ください');
      })
    });
  } catch(e) { // FireFox は ClipboardItem が使えない（2022/07/16 v.102.0.1）
    return {
      getType: ()=>{
        return new Promise((resolve, reject)=>{
          getCcfoliaJson().then((json)=>{
            resolve(new Blob([json]));
          });
        }, (err)=>{
          console.error(err);
          alert('キャラクターシートのデータ取得に失敗しました。通信状況等をご確認ください');
        });
      }
    };
  }
}

function clipboardItemToTextareaClipboard(clipboardItem) {
  clipboardItem.getType('text/plain').then((blob)=>{
    blob.text().then((jsonText)=>{
      try {
        copyToClipboard(jsonText);
        alert('クリップボードにコピーしました。ココフォリアにペーストすることでデータを取り込めます');
      } catch (e) {
        popTextareaForCopy(jsonText);
      }
    });
  });
}

async function downloadAsCcfolia() {
  const clipboardItem = getClipboardItem();
  if(navigator.clipboard && navigator.clipboard.write) { // FireFox は navigator.clipboard.write が使えない（2022/07/16 v.102.0.1）
    navigator.clipboard.write([clipboardItem]).then((ok)=>{
      alert('クリップボードにコピーしました。ココフォリアにペーストすることでデータを取り込めます');
    }, (err)=>{
      clipboardItemToTextareaClipboard(clipboardItem);
    });
  } else {
    clipboardItemToTextareaClipboard(clipboardItem);
  }  
}

async function downloadAsText() {
  const characterDataJson = await getJsonData();
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const textData = output[`generateCharacterTextOf${generateType}`](characterDataJson);
  const textUrl = window.URL.createObjectURL(new Blob([ textData ], { "type" : 'text/plain;charset=utf-8;' }));
  downloadFile(`${name}.txt`, textUrl);
}

async function downloadAsJson() {
  const characterDataJson = await getJsonData();
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const jsonUrl = window.URL.createObjectURL(new Blob([ JSON.stringify(characterDataJson) ], { "type" : 'text/json;charset=utf-8;' }));
  downloadFile(`${name}.json`, jsonUrl);
}
async function downloadAsHtml(){
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const url = location.href.replace(/#(.+)$/,'').replace(/&mode=(.+?)(&|$)/,'')+'&mode=download';
  downloadFile(name+'.html', url);
}
async function downloadAsFullSet(){
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const url = location.href.replace(/#(.+)$/,'').replace(/&mode=(.+?)(&|$)/,'');
  let zip = new JSZip();
  zip.file(name+'.html', await JSZipUtils.getBinaryContent(url+'&mode=download'));
  zip.file(name+'.json', await JSZipUtils.getBinaryContent(url+'&mode=json'));
  if(document.getElementById('chatPaletteBox')) zip.file(name+'_チャットパレット.txt', await JSZipUtils.getBinaryContent(url+'&mode=palette'));
  
  // ユドナリウム
  if(document.getElementById('downloadlist-udonarium')){
    const characterDataJson = await getJsonData('udonarium');
    
    const image = await output.getPicture(characterDataJson.imageURL || defaultImage, "image."+characterDataJson.image);
    const udonariumXml = output[`generateUdonariumXml`](generateType,characterDataJson, location.href, image.hash);
    const udonariumUrl = await generateUdonariumZipFile((characterDataJson.characterName||characterDataJson.aka), udonariumXml, image);
    zip.file(name+'_udonarium.zip', await JSZipUtils.getBinaryContent(udonariumUrl));
  }
  // ココフォリア
  if(document.getElementById('downloadlist-ccfolia')){
    zip.file(name+'_ccfolia.txt', await getCcfoliaJson());
  }

  // ダウンロード
  zip.generateAsync({type:"blob"})
    .then(function(content) {
      const url = URL.createObjectURL(content);
      const a = document.createElement("a");
      document.body.appendChild(a);
      a.download = name+'.zip';
      a.href = url;
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    });
}

window.addEventListener(
    'load',
    () => {
      /**
       * @param {string} source
       * @return {string}
       */
      function makeSnippet(source) {
        const matches = source.matchAll(/[1-2][dｄＤ](?:\[[\d>=:\-+]+])?(?:[-－+＋*×]\S+)?|k\d+(?:\[\d+])?(?:[-－+＋]\S+)?|@[HM]P[-+]\d+/gi);
        let lastIndex = 0;
        const parts = [];

        for (const match of matches) {
          parts.push(source.substring(lastIndex, match.index));
          parts.push(`<snippet>${match[0]}</snippet>`);
          lastIndex = match.index + match[0].length;
        }

        parts.push(source.substring(lastIndex));

        return parts.join('');
      }

      /**
       * @param {HTMLElement} element
       * @param {string} mode
       * @return {string}
       */
      function elementToText(element, mode) {
        /** @var {string[]} */
        const parts = [];

        for (/** @var {HTMLElement} child */const child of element.childNodes) {
          switch (child.nodeName) {
            case '#text':
              parts.push(makeSnippet(child.textContent));
              continue;
            case 'SECTION':
              continue;
            case 'H1':
            case 'H2':
            case 'H3':
            case 'H4':
            case 'H5':
            case 'H6':
              parts.push(`<b>${elementToText(child, 'inline')}</b>`);
              continue;
            case 'P':
              parts.push(elementToText(child, 'inline'));
              continue;
            case 'DL':
              if (child.classList.contains('note-description')) {
                const items = [];
                let lastTerm;
                child.querySelectorAll('& > :is(dt, dd)').forEach(
                    x => {
                      switch (x.nodeName) {
                        case 'DT':
                          lastTerm = elementToText(x, 'inline');
                          break;
                        case 'DD':
                          items.push(`${lastTerm}：${elementToText(x, 'inline')}`);
                          lastTerm = null;
                          break;
                      }
                    }
                );
                parts.push(items.map(x => `・${x}`).join('\n'));
                continue;
              }
              break;
            case 'I':
              if (child.classList.contains('s-icon')) {
                parts.push(child.textContent.trim());
                continue;
              }
              break;
            case 'SPAN':
              switch (child.getAttribute('class') ?? '') {
                case 'underline':
                  parts.push(`__${elementToText(child, 'inline')}__`);
                  continue;
              }
              break;
          }

          console.warn('Unexpected node type: ' + child.nodeName);
          console.warn(child);
        }

        return parts.join(mode === 'block' ? '\n' : '');
      }

      document.querySelectorAll('section > :is(h1, h2, h3, h4, h5, h6).copyable').forEach(
          headlineElement => {
            const section = headlineElement.closest('section');
            const text = elementToText(section, 'block');

            const icon = document.createElement('i');
            icon.classList.add('icon', 'to-copy');

            icon.addEventListener(
                'click',
                () => navigator.clipboard.writeText(text)
            );

            headlineElement.appendChild(icon);
          }
      );
    }
);
