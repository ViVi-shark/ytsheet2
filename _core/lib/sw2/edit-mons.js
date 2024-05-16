"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  setName();
  rewriteMountLevel();
  updatePartsAutomatically();
  updatePartList();
  selectInputCheck(form.taxa,'その他')
  checkKind();
  updateGolemReinforcementItemGrade(false);
  updateGolemReinforcementItemPartRestriction();
  switchHabitatReplacement();
  switchLoots();
  swordFragmentNumChanged();
  individualizationModeChanged();

  changeColor();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.monsterName.value === '' && form.characterName.value === ''){
    alert('名称か名前のいずれかを入力してください。');
    form.monsterName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}

// 名前 ----------------------------------------
function setName(){
  let m = ruby(form.monsterName.value);
  let c = ruby(form.characterName.value);
  document.querySelector('#header-menu > h2 > span').innerHTML = c && m ? `${c}<small>（${m}）</small>` : (c || m || '(名称未入力)');

  function vCheck(id){
    if(form[id]){ return form[id].value; }
    else { return '' }
  }
}
// 魔物／騎獣／ゴーレムの区別 ----------------------------------------
let mountFlag = 0;
function checkKind() {
  document.querySelectorAll('[type="radio"][name="kind"]').forEach(
      radioButton => {
        if (!radioButton.checked) {
          return;
        }

        const value = radioButton.getAttribute('value');

        const mount = document.querySelector('[name="mount"]');
        const golem = document.querySelector('[name="golem"]');

        mountFlag = value === 'mount';
        const isGolem = value === 'golem';

        mount.setAttribute('value', mountFlag ? '1' : '0');
        golem.setAttribute('value', isGolem ? '1' : '0');

        form.classList.toggle('mount', mountFlag);
        form.classList.toggle('golem', isGolem);

        if (isGolem) {
          /** @var {Array<{name: string, value: string}>} */
          const preset = [
            {name: 'taxa', value: "魔法生物"},
            {name: 'intellect', value: "命令を聞く"},
            {name: 'perception', value: "魔法"},
            {name: 'disposition', value: "命令による"},
            {name: 'language', value: "なし"},
            {name: 'habitat', value: "さまざま"}
          ];

          preset.forEach(
              x => {
                const control = document.querySelector(`[name="${x.name}"]`);
                control.value = x.value;
                control.dispatchEvent(new Event('input'));
              }
          );
        }
      }
  );
}
document.querySelectorAll('[type="radio"][name="kind"]').forEach(
    radioButton => radioButton.addEventListener(
        'input',
        () => checkKind()
    )
);
// 騎獣 ----------------------------------------
function checkMount(){
  mountFlag = form.mount.checked ? 1 : 0;
  form.classList.toggle('mount', mountFlag);
}
function checkLevel(){
  if(mountFlag){
    checkMountLevel();
  }
}
// 各ステータス計算 ----------------------------------------
function calcVit(){
  const val = form.vitResist.value;
  form.vitResistFix.value = (val == '') ? '' : Number(val) + 7;
}
function calcVitF(){
  const val = form.vitResistFix.value;
  form.vitResist.value    = (val == '') ? '' : Number(val) - 7;
}
function calcMnd(){
  const val = form.mndResist.value;
  form.mndResistFix.value = (val == '') ? '' : Number(val) + 7;
}
function calcMndF(){
  const val = form.mndResistFix.value;
  form.mndResist.value    = (val == '') ? '' : Number(val) - 7;
}
function calcAcc(Num){
  const val = form['status'+Num+'Accuracy'].value;
  form['status'+Num+'AccuracyFix'].value = (val == '') ? '' : Number(val) + 7;
}
function calcAccF(Num){
  const val = form['status'+Num+'AccuracyFix'].value;
  form['status'+Num+'Accuracy'].value    = (val == '') ? '' : Number(val) - 7;
}
function calcEva(Num){
  const val = form['status'+Num+'Evasion'].value;
  form['status'+Num+'EvasionFix'].value  = (val == '') ? '' : Number(val) + 7;
}
function calcEvaF(Num){
  const val = form['status'+Num+'EvasionFix'].value;
  form['status'+Num+'Evasion'].value     = (val == '') ? '' : Number(val) - 7;
}

// ステータス欄 ----------------------------------------
function checkMountLevel(){
  let min = Number(form.lvMin.value) || 0;
  let max = Number(form.lvMax.value) || 0;
  if(max < min){ form.lvMax.value = max = min }
  if(form.lv.value != ''){
    if(form.lv.value < min){ form.lv.value = min }
    if(form.lv.value > max){ form.lv.value = max }
  }
  let gap = max - min;
  gap = gap < 0 ? 0 : gap;
  if(gap > 0){
    for(let lv = 2; lv <= gap+1; lv++){
      if(!document.getElementById(`status-tbody${lv}`)){
        let tbody = document.createElement("tbody");
        tbody.classList.add('mount-only');
        tbody.id = `status-tbody${lv}`;
        tbody.dataset.lv = lv;
        document.getElementById('status-table').append(tbody);
        for(let num = 1; num <= form.statusNum.value; num++){
          addStatusInsert(tbody, num);
        }
      }
    }
  }
  for(let lv = gap+2; document.getElementById(`status-tbody${lv}`); lv++){
    document.getElementById(`status-tbody${lv}`).remove();
  }
  for(let num = 1; num <= form.statusNum.value; num++){ checkStyle(num); }
  rewriteMountLevel(min);

  if (document.getElementById('monster').classList.contains('individualization')) {
    document.getElementById('source-status-table').dataset.selectedLevel = form.lv.value.toString();
  }
}
function rewriteMountLevel(level){
  level ||= form.lvMin.value;
  document.querySelectorAll("#status-table tbody tr th:first-child").forEach(obj => {
    obj.textContent = '';
  });
  document.querySelectorAll("#status-table tbody tr:first-child th:first-child").forEach(obj => {
    obj.textContent = level;
    obj.classList.toggle('current', level == form.lv.value);
    level++;
  });
}
// 攻撃方法
function checkStyle(num){
  document.querySelectorAll(`#status-table .name[data-style="${num}"]`).forEach(obj => {
    obj.textContent = form[`status${num}Style`].value;
  });
}
// 追加・複製
function addStatus(copy){
  let num = Number(form.statusNum.value) + 1;
  document.querySelectorAll("#status-table tbody").forEach(obj => {
    addStatusInsert(obj, num, copy);
  });
  form.statusNum.value = num;
  statusTextInputToggle();
  updatePartsAutomatically();
}
function addStatusInsert(target, num, copy){
  const lv = target.dataset.lv ? '-'+target.dataset.lv : '';
  const ini = {
    "style"      : copy && !lv ? form[`status${copy}${lv}Style`       ].value : '',
    "accuracy"   : copy        ? form[`status${copy}${lv}Accuracy`    ].value : '',
    "accuracyFix": copy && !lv ? form[`status${copy}${lv}AccuracyFix` ].value : '',
    "damage"     : copy        ? form[`status${copy}${lv}Damage`      ].value : '2d+',
    "evasion"    : copy        ? form[`status${copy}${lv}Evasion`     ].value : '',
    "evasionFix" : copy && !lv ? form[`status${copy}${lv}EvasionFix`  ].value : '',
    "defense"    : copy        ? form[`status${copy}${lv}Defense`     ].value : '',
    "hp"         : copy        ? form[`status${copy}${lv}Hp`          ].value : '',
    "mp"         : copy        ? form[`status${copy}${lv}Mp`          ].value : '',
    "vit"        : copy        ? form[`status${copy}${lv}Vit`         ].value : (num == 1 ? '' : '―'),
    "mnd"        : copy        ? form[`status${copy}${lv}Mnd`         ].value : (num == 1 ? '' : '―'),
  };
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('status-row',lv));
  tr.innerHTML = `
    <th class="mount-only"></th>
    <td ${ lv ? '' : `class="handle"`}></td>
    <td ${ lv ? 'class="name"' : ``} data-style="${num}">${ lv ? form[`status${num}Style`].value : `<input name="status${num}${lv}Style" type="text" value="${ini.style}" oninput="checkStyle(${num}${lv}); updatePartsAutomatically();">` }</td>
    <td>
      <input name="status${num}${lv}Accuracy" type="text" oninput="calcAcc('${num}${lv}')" value="${ini.accuracy}"><span class="monster-only calc-only"><br>
      (<input name="status${num}${lv}AccuracyFix" type="text" oninput="calcAccF('${num}${lv}')" value="${ini.accuracyFix}">)</span>
    </td>
    <td><input name="status${num}${lv}Damage" type="text" value="${ini.damage}"></td>
    <td>
      <input name="status${num}${lv}Evasion" type="text" oninput="calcEva('${num}${lv}')" value="${ini.evasion}"><span class="monster-only calc-only"><br>
      (<input name="status${num}${lv}EvasionFix" type="text" oninput="calcEvaF('${num}${lv}')" value="${ini.evasionFix}">)</span>
    </td>
    <td><input name="status${num}${lv}Defense" type="text" value="${ini.defense}"></td>
    <td><input name="status${num}${lv}Hp" type="text" value="${ini.hp}"></td>
    <td><input name="status${num}${lv}Mp" type="text" value="${ini.mp}"></td>
    <td class="mount-only"><input name="status${num}${lv}Vit" type="text" value="${ini.vit}"></td>
    <td class="mount-only"><input name="status${num}${lv}Mnd" type="text" value="${ini.mnd}"></td>
    <td>${ lv ? '' : `<span class="button" onclick="addStatus('${num}${lv}');">複<br>製</span>` }</td>
  `;
  target.appendChild(tr, target);
}
// 削除
function delStatus(force = false){
  let num = Number(form.statusNum.value);
  if(num > 1){
    let hasValue = false;
    for (const node of document.querySelectorAll(`#status-table tbody tr:last-child input`)){
      if(
        node.value !== '' &&
        !(/Damage$/.test(node.getAttribute('name')) && node.value === '2d+') &&
        !(/Vit$/.test(node.getAttribute('name')) && node.value === '―') &&
        !(/Mnd$/.test(node.getAttribute('name')) && node.value === '―')
      ){
        hasValue = true; break;
      }
    }
    if(hasValue){
      if (!force && !confirm(delConfirmText)){ return false; }
    }
    document.querySelectorAll("#status-table tbody tr:last-child").forEach(target => {
      target.remove();
    });
    num--;
    form.statusNum.value = num;
  }
  updatePartsAutomatically();
}
// ソート
(() => {
  let sortable = Sortable.create(document.querySelector('#status-table tbody'), {
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot',
    onUpdate: function (evt) {
      const order = sortable.toArray();
      let num = 1;
      for(let id of order) {
        const row = document.querySelector(`tr#${id}`);
        if(!row) continue;
        row.querySelectorAll('[name]').forEach(inputField => {
          const beforeName = inputField.getAttribute('name');
          const afterName = beforeName.replace(/^(status)\d+(.+)$/, `$1${num}$2`);
          inputField.setAttribute('name', afterName)
        });
        row.querySelectorAll('[oninput]').forEach(inputField => {
          const beforeName = inputField.getAttribute('oninput');
          const afterName = beforeName.replace(/\(\d+\)/, `(${num})`);
          inputField.setAttribute('oninput', afterName)
        });
        row.querySelector(`span[onclick]`).setAttribute('onclick',`addStatus(${num})`);
        num++;
      }
      const moved  = evt.item.id;
      const before = evt.item.previousElementSibling ? evt.item.previousElementSibling.id : '';
      document.querySelectorAll("#status-table tbody").forEach(obj => {
        const lv = obj.dataset.lv;
        if(lv){
          if(before){
            document.getElementById(before+'-'+lv).after(document.getElementById(moved+'-'+lv));
          }
          else {
            document.getElementById(`status-tbody${lv}`).prepend(document.getElementById(moved+'-'+lv))
          }
          let num = 1;
          for(let id of order) {
            const row = document.querySelector(`tr#${id}-${lv}`);
            if(!row) continue;
            row.querySelectorAll('[name]').forEach(inputField => {
              const beforeName = inputField.getAttribute('name');
              const afterName = beforeName.replace(/^(status)\d+-(.+)$/, `$1${num}-$2`);
              inputField.setAttribute('name', afterName)
            });
            row.querySelector(`.name`).dataset.style = num;
            num++;
          }
        }
      });
      rewriteMountLevel();
      updatePartsAutomatically();
    }
  });
})();
//
function statusTextInputToggle(){
  const on = form.statusTextInput.checked ? 1 : form.mount.checked ? 1 : 0;
  form[`vitResist`].type    = on ? 'text'   : 'number';
  form[`mndResist`].type    = on ? 'text'   : 'number';
  for(let i = 1; i <= form.statusNum.value; i++){
    form[`status${i}Accuracy`].type    = on ? 'text'   : 'number';
    form[`status${i}Evasion`].type     = on ? 'text'   : 'number';
  }
  form.classList.toggle('not-calc', on)
}
// 部位数・内訳の自動入力
function updatePartsAutomatically() {
  const manualModeCheckbox = document.querySelector('input[type="checkbox"][name="partsManualInput"]');
  const partsNumInput = document.querySelector('.parts input[name="partsNum"]');
  const partsNamesInput = document.querySelector('.parts input[name="parts"]');

  if (manualModeCheckbox.checked) {
    partsNumInput.readOnly = false;
    partsNamesInput.readOnly = false;
    return;
  }

  let partCount = 0;
  const partNames = [];
  document.querySelectorAll('#status-tbody input[name$="Style"]').forEach(
      input => {
        partCount++;

        const style = input.value.trim();
        const m = style.match(/.*[(（](.+?)[）)]$/);
        if (m == null) {
          return;
        }
        partNames.push(m[1].trim());
      }
  );

  partsNumInput.readOnly = true;
  partsNumInput.value = partCount.toString();
  partsNumInput.dispatchEvent(new Event('input'));

  partsNamesInput.readOnly = true;
  partsNamesInput.value = partNames.length === 0 ? '' : partNames.reduce(
      (previous, currentPartName) => {
        const previousPartTexts = previous.split('／');
        const lastPartText = previousPartTexts[previousPartTexts.length - 1];
        const m = lastPartText.match(/^(.+?)(?:×(\d+))?$/);
        const lastPartName = m[1];
        const lastPartCount = m[2] ? parseInt(m[2]) : 1;
        return currentPartName === lastPartName
            ? `${previousPartTexts.length > 1 ? `${previousPartTexts.slice(0, -1).join('／')}／` : ''}${lastPartName}×${lastPartCount + 1}`
            : `${previous}／${currentPartName}`;
      }
  );
  partsNamesInput.dispatchEvent(new Event('input'));
}
function updatePartList() {
  const partNumText = document.querySelector('input[name="partsNum"]').value.trim();
  const partNum = partNumText === '' ? 0 : parseInt(partNumText);

  const corePartsInput = document.querySelector('input[name="coreParts"]');
  if (!isNaN(partNum) && partNum > 1) {
    corePartsInput.removeAttribute('disabled');
  } else {
    corePartsInput.setAttribute('disabled', '');
  }

  const partsText = document.querySelector('input[name="parts"]').value.trim();

  const items =
      partsText
          .split(/[/／]/)
          .map(x => x.trim())
          .filter(x => x !== '')
          .map(part => part.replace(/[*×][\d０１２３４５６７８９]+$/, '（すべて）'));

  const datalist = document.getElementById('list-of-core-part');
  datalist.innerHTML = '';

  if (items.length === 0) {
    return;
  }

  items.unshift("なし");

  items.forEach(
      item => {
        const option = document.createElement('option');
        option.textContent = item;
        datalist.appendChild(option);
      }
  );
}

// ゴーレム強化アイテム ----------------------------------------
function updateGolemReinforcementItemGrade(force = true) {
  if (form.classList.contains('individualization')) {
    return;
  }

  const gradeSelector = document.querySelector('[name="reinforcementItemGrade"]');
  const selectedGrade = gradeSelector.value;
  const gradeIndex = ['小', '中', '大', '極大'].indexOf(selectedGrade);

  if (gradeIndex < 0) {
    return;
  }

  document.querySelectorAll('.reinforcement-items .items dd.price input').forEach(
      input => {
        if (input.value !== '' && !force) {
          return;
        }

        input.value = input.dataset.prices.split('|')[gradeIndex] ?? '';
        input.dispatchEvent(new Event('input'));
      }
  );

  document.querySelectorAll('.reinforcement-items .items dd.ability').forEach(
      dd => {
        dd.dataset.suffix = dd.dataset.suffixes.split('|')[gradeIndex] ?? '';
      }
  );
}
function updateGolemReinforcementItemPartRestriction() {
  const partNames =
      document.querySelector('form#monster [name="parts"]').value
          .split(/[/／]/)
          .map(x => x.trim().replace(/×\d+$/, '').trim())
          .filter(x => x !== '');

  const datalist = document.getElementById('golem-reinforcement-item-part-restriction-list');
  datalist.innerHTML = '';

  partNames.forEach(
      partName => {
        const option = document.createElement('option');
        option.textContent = `${partName}のみ`;
        datalist.appendChild(option);
      }
  );

  document.querySelectorAll('.reinforcement-items dd.item input').forEach(
      x => {
        const supported = x.closest('dd.item').classList.contains('supported');

        if (x.getAttribute('name').endsWith('partRestriction')) {
          if (supported && partNames.length > 0) {
            x.removeAttribute('disabled');
          } else {
            x.setAttribute('disabled', '');
          }
        } else {
          if (supported) {
            x.removeAttribute('disabled');
          } else {
            x.setAttribute('disabled', '');
          }
        }
      }
  );

  document.querySelector('.reinforcement-items > .items').classList.toggle('hide-part-restriction', partNames.length === 0);
}
document.querySelector('form#monster [name="parts"]').addEventListener(
    'input',
    () => updateGolemReinforcementItemPartRestriction()
);
document.querySelectorAll('.reinforcement-items [type="checkbox"][name$="_supported"]').forEach(
    checkbox =>
        checkbox.addEventListener(
            'input',
            () => {
              const dt = checkbox.closest('dt.item');
              dt.classList.toggle('supported', checkbox.checked);
              dt.nextElementSibling?.classList.toggle('supported', checkbox.checked);

              updateGolemReinforcementItemPartRestriction();
            }
        )
);

// 戦利品欄 ----------------------------------------
// 追加
function addLoots(){
  let num = Number(form.lootsNum.value) + 1;
  let liNum = document.createElement('li');
  let liItem = document.createElement('li');
  liNum.id= idNumSet("loots-num");
  liItem.id= idNumSet("loots-item");
  liNum.innerHTML = '<span class="handle"></span><input type="text" name="loots'+num+'Num">';
  liItem.innerHTML = '<span class="handle"></span><input type="text" name="loots'+num+'Item">';
  document.getElementById("loots-num").appendChild(liNum);
  document.getElementById("loots-item").appendChild(liItem);
  
  form.lootsNum.value = num;
}
// 削除
function delLoots(force = false){
  let num = Number(form.lootsNum.value);
  if(num > 1){
    if(form[`loots${num}Num`].value || form[`loots${num}Item`].value){
      if (!force && !confirm(delConfirmText)) return false;
    }
    const listNum  = document.getElementById("loots-num");
    const listItem = document.getElementById("loots-item");
    listNum.lastElementChild.remove();
    listItem.lastElementChild.remove();
    num--;
    form.lootsNum.value = num;
  }
}
// ソート
setSortable('loots','#loots-num');
setSortable('loots','#loots-item');
function addAdditionalLoots() {
  const num = Number(form.additionalLootsNum.value) + 1;

  const li = document.getElementById('template-of-additional-loot').content.firstElementChild.cloneNode(true);
  li.id = idNumSet("additional-loots-item");
  li.querySelector('input').setAttribute('name', `additionalLoots${num}Item`);
  document.getElementById('additional-loots-item').appendChild(li);

  form.additionalLootsNum.value = num;
}
function delAdditionalLoots() {
  const num = Number(form.additionalLootsNum.value);

  if (num > 1) {
    if (form[`additionalLoots${num}Item`].value) {
      if (!confirm(delConfirmText)) {
        return false;
      }
    }

    document.querySelector('#additional-loots-item > li:last-of-type').remove();
    form.additionalLootsNum.value = num - 1;
  }
}
setSortable('additionalLoots', '#additional-loots-item');

// 個別化 ----------------------------------------
let lastSourceTimestamp;
function individualizationSourceUrlChanged() {
  const sourceUrlInput = document.querySelector('.individualization-area input[name="sourceMonsterUrl"]');

  const url = sourceUrlInput.value.trim();

  if (!/^https?:\/\//.test(url)) {
    return;
  }

  const now = lastSourceTimestamp = Date.now().toString();
  fetch(`${url}&mode=json`)
      .then(x => x.json())
      .then(
          source => {
            delete source['result'];

            if (now !== lastSourceTimestamp) {
              return;
            }

            const isMount = source['mount']?.toString() === '1';
            const isGolem = source['golem']?.toString() === '1';

            form.classList.toggle('mount', isMount);
            form.classList.toggle('golem', isGolem);
            document.querySelector('#group span.is-mount').dataset.isMount = isMount.toString();
            document.querySelector('#group span.is-golem').dataset.isGolem = isGolem.toString();

            {
              const kind = isMount ? 'mount' : isGolem ? 'golem' : 'monster';

              document.querySelectorAll('#group [type="radio"][name="kind"]').forEach(x => x.checked = false);

              const selectingRadio = document.querySelector(`#group [type="radio"][name="kind"][value="${kind}"]`);
              selectingRadio.checked = true;
              selectingRadio.dispatchEvent(new Event('input'));
            }

            if (isMount) {
              checkLevel();
            }

            Object.keys(source).forEach(
                key => {
                  if (!/^(?:description|skills|golemReinforcement_.+_details)$/.test(key) || source[key] == null) {
                    return;
                  }

                  source[key] = source[key]
                      .replaceAll(/&lt;/g, '<')
                      .replaceAll(/&gt;/g, '>')
                      .replaceAll(/<br>/gi, '\n');
                }
            );

            Object.keys(source)
                .filter(x => /^(?:materialPrice(?:Normal|Higher))$/.test(x))
                .forEach(x => source[x] = commify(source[x]));

            const statusNum = parseInt((
                source['statusNum'] != null && source['statusNum'] !== ''
                    ? source['statusNum']
                    : 1
            ).toString());

            while (parseInt(form.statusNum.value) > statusNum) {
              delStatus(true);
            }

            while (parseInt(form.statusNum.value) < statusNum) {
              addStatus();
            }

            const lootsNum = parseInt((
                source['lootsNum'] != null && source['lootsNum'] !== ''
                    ? source['lootsNum']
                    : 1
            ).toString());

            while (parseInt(form.lootsNum.value) > lootsNum) {
              delLoots(true);
            }

            while (parseInt(form.lootsNum.value) < lootsNum) {
              addLoots();
            }

            {
              const mountEquipmentList = document.querySelector('.mount-equipments dl.parts');
              const template = document.getElementById('template-of-mount-equipment-part');

              const oldValues = {};

              document.querySelectorAll('#loaded-data [name]').forEach(
                  x => {
                    const name = x.getAttribute('name');
                    if (name.startsWith('partEquipment')) {
                      oldValues[name] = x.getAttribute('value');
                    }
                  }
              );

              mountEquipmentList.querySelectorAll('input[name]').forEach(
                  input => oldValues[input.getAttribute('name')] = input.value
              );

              mountEquipmentList.innerHTML = '';

              for (let i = 1; i <= statusNum; i++) {
                const dt = template.content.querySelector('dt.part').cloneNode(true);
                dt.textContent = source[`part${i}`] ?? '';
                mountEquipmentList.appendChild(dt);

                const dd = template.content.querySelector('dd.part').cloneNode(true);
                dd.dataset.partSerial = i.toString();
                mountEquipmentList.appendChild(dd);

                dd.querySelectorAll('input').forEach(
                    input => {
                      const partSerial = input.closest('[data-part-serial]').dataset.partSerial;
                      const nameGroup = input.closest('[data-name-group]').dataset.nameGroup;
                      const propertyName = input.dataset.propertyName;

                      const name = `partEquipment${partSerial}-${nameGroup}-${propertyName}`;
                      input.setAttribute('name', name);
                      input.value = oldValues[name] ?? '';

                      input.addEventListener(
                          'input',
                          e => {
                            const offset = e.target.value.trim();
                            document.querySelectorAll(`#source-status-table [data-part-serial="${partSerial}"] [data-property-name="${propertyName}"]`)
                                .forEach(
                                    td => {
                                      (td.querySelector('.base .equipment-offset') ?? td.querySelector('.equipment-offset')).dataset.offset = offset;

                                      {
                                        const fixed = td.querySelector('.fixed .equipment-offset');
                                        if (fixed != null) {
                                          fixed.dataset.offset = offset;
                                        }
                                      }
                                    }
                                );
                          }
                      );

                    }
                );
              }
            }

            for (const [key, value] of Object.entries(source)) {
              if (
                  ['birthTime', 'id', 'mode', 'protect', 'protectOld', 'type', 'updateTime', 'ver'].includes(key) || // システム用の値
                  /^(?:color(?:Base|Head)|forbidden$|gameVersion$|hide$|palette|part\d+$|sheetDescription[SM]$|unit(?:Except)?Status|taxaSelect$)/i.test(key) || // このへんは無視する
                  key === 'individualization' || // 個別化チェックそのものは無視する
                  key === 'sourceMonsterUrl' || // 個別化の元データＵＲＬも無視する
                  ['characterName', 'tags'].includes(key) || // 名前・タグは上書き可能
                  ['mount', 'golem'].includes(key) || // 騎獣／ゴーレムの是非は解決済み
                  key === 'statusNum' || // 部位数は解決済み
                  /^status\d.*Fix$/.test(key) && isMount || // 騎獣の場合は固定達成値を無視
                  key === 'lootsNum' || // 戦利品の行数は解決済み
                  (isMount && key === 'lv') // 騎獣レベルは上書き可能
              ) {
                continue;
              }

              const control = document.querySelector(`form#monster [name="${key}"]`);

              if (control == null) {
                console.warn(`Control '${key}' is not found.`);
                continue;
              }

              if (control instanceof HTMLInputElement) {
                switch (control.getAttribute('type').toLowerCase()) {
                  case 'hidden':
                    if (/^(?:(?:loots|status)Num|mount|golem)$/i.test(key)) {
                      control.value = value != null ? value.toString() : '';
                      continue;
                    }
                    break;
                  case 'text':
                  case 'number':
                    control.value = value != null ? value.toString() : '';
                    control.dispatchEvent(new Event('input'));
                    continue;
                  case 'checkbox':
                    control.checked = value === '1' || value === 1 || value === true || value === 'on';
                    control.dispatchEvent(new Event('input'));
                    continue;
                  case 'radio':
                    control
                        .closest('form, fieldset')
                        .querySelectorAll(`form#monster [type="radio"][name="${key}"]`)
                        .forEach(
                            control => control.checked = control.getAttribute('value') === value
                        );
                    continue;
                }
              } else if (control instanceof HTMLTextAreaElement) {
                control.value = value != null ? value.toString() : '';
                control.dispatchEvent(new Event('input'));
                continue;
              } else if (control instanceof HTMLSelectElement) {
                control.selectedIndex = [...control.options].map(x => x.value).indexOf(value);
                control.dispatchEvent(new Event('input'));
                continue;
              }

              console.warn([key, control]);
            }

            {
              const container = document.querySelector('.status .mobility dd.individualization-only');
              container.innerHTML = '';

              source['mobility'].split(/[\/／]/).map(x => x.trim()).filter(x => x !== '').forEach(
                  x => {
                    const m = x.match(/^([0-9０１２３４５６７８９]+?)(?:[(（](.+?)[）)])?$/);
                    const value = m != null ? m[1] : null;
                    const form = m != null ? m[2] : null;

                    const span = document.createElement('span');

                    if (value == null) {
                      span.textContent = x;
                    } else {
                      span.textContent = value;

                      const offset = document.createElement('span');
                      offset.classList.add('offset');
                      span.appendChild(offset);

                      if (form != null) {
                        const formNode = document.createElement('span');
                        formNode.classList.add('form');
                        formNode.textContent = form;
                        span.appendChild(formNode);
                      }
                    }

                    container.appendChild(span);
                  }
              );
            }

            document.querySelector('#section-common > .parts').dataset.partCount = source['partsNum'] ?? '';

            {
              const sourceStatusTable = document.getElementById('source-status-table');

              sourceStatusTable.querySelectorAll('tbody').forEach(x => x.remove());

              const levelMin = source['mount']?.toString() === '1' ? parseInt(source['lvMin']) : parseInt(source['lv']);
              const levelMax = source['mount']?.toString() === '1' ? parseInt(source['lvMax']) : levelMin;

              const partSerials =
                  Array.from(new Set(
                      Object.keys(source)
                          .filter(x => /^status\d+/i.test(x))
                          .map(x => x.match(/^status(\d+)/i)[1])
                  ))
                      .map(x => parseInt(x))
                      .sort((x, y) => x - y);

              for (let level = levelMin; level <= levelMax; level++) {
                const tbody = document.createElement('tbody');
                tbody.dataset.level = level.toString();
                sourceStatusTable.appendChild(tbody);

                partSerials.forEach(
                    partSerial => {
                      const tr = document.getElementById('template-of-part').content.firstElementChild.cloneNode(true);
                      tr.dataset.partSerial = partSerial.toString();
                      tbody.appendChild(tr);

                      ['Style', 'Accuracy', 'Damage', 'Evasion', 'Defense', 'Hp', 'Mp', 'Vit', 'Mnd'].forEach(
                          propertyName => {
                            const key = `status${partSerial}${propertyName !== 'Style' && level > levelMin ? `-${level - levelMin + 1}` : ''}${propertyName}`;
                            const td = tr.querySelector(`.${propertyName.toLowerCase()}`);

                            (td.querySelector('.base .value') ?? td.querySelector('.value') ?? td).textContent =
                                source[key]?.toString();

                            if (`${key}Fix` in source) {
                              (td.querySelector('.fixed .value') ?? td.querySelector('.fixed')).textContent =
                                  source[`${key}Fix`]?.toString();
                            }

                            if (isGolem && (propertyName === 'Hp' || propertyName === 'Mp')) {
                              for (const itemName of ['garnet-energy', 'garnet-life']) {
                                const span = document.createElement('span');
                                span.classList.add('offset', `offset-of-${itemName}`);
                                (td.querySelector('.standard') ?? td).appendChild(span);
                              }
                            }

                            {
                              const modificationInput = td.querySelector('.modification input');

                              if (modificationInput != null) {
                                const name = `status${partSerial}${propertyName !== 'Style' && level > levelMin ? `-${level - levelMin + 1}` : ''}${propertyName}Modification`;

                                modificationInput.setAttribute('name', name);

                                modificationInput.value =
                                    document.querySelector(`#loaded-data [name="${name}"]`)?.value ?? '';
                              }
                            }
                          }
                      );
                    }
                );

                {
                  const levelNode = tbody.querySelector('tr:first-child th');
                  if (partSerials.length > 1) {
                    levelNode.setAttribute('rowspan', partSerials.length.toString());
                  }
                  levelNode.textContent = level.toString();
                }

                tbody.querySelectorAll('tr:not(:first-child) th').forEach(x => x.remove());
              }
            }

            {
              /** @var {Object<string, int>} */
              const oldValues = {};

              document.querySelectorAll('#loaded-data [name]').forEach(
                  x => {
                    const name = x.getAttribute('name');
                    if (/^swordFragment_[hm]pOffset_part\d+$/.test(name)) {
                      const value = x.getAttribute('value');
                      oldValues[name] = /^\d+$/.test(value) ? parseInt(value) : null;
                    }
                  }
              );

              const sourceStatusTable = document.getElementById('source-status-table');

              const offsetDistributionTable =
                  document.querySelector('.sword-fragment-box .offset-distribution');

              const offsetDistributionTableBody = offsetDistributionTable.querySelector('tbody');
              const offsetDistributionTableFooter = offsetDistributionTable.querySelector('tfoot');

              const rowTemplate = document.getElementById('template-of-sword-fragment-offset-distribution-row');

              offsetDistributionTableBody.innerHTML = '';

              /** @var {Function[]} */
              const functionsToSetupInput = [];

              let partCount = 0;

              sourceStatusTable.querySelectorAll('tbody tr').forEach(
                  sourceRow => {
                    const partName = sourceRow.querySelector('.style').textContent.trim()
                        .replace(/^.+[(（](.+?)[）)]$/, '$1');

                    const partSerial = sourceRow.dataset.partSerial;

                    const hp = parseInt(sourceRow.querySelector('.hp .value').textContent.trim());
                    const mp = parseInt(sourceRow.querySelector('.mp .value').textContent.trim());

                    const row = rowTemplate.content.firstElementChild.cloneNode(true);
                    row.querySelector('.part-name').textContent = partName;
                    row.querySelector('.hp.base').textContent = isNaN(hp) ? '―' : hp.toString();
                    row.querySelector('.mp.base').textContent = isNaN(mp) ? '―' : mp.toString();

                    for (const propertyName of ['hp', 'mp']) {
                      const name = `swordFragment_${propertyName}Offset_part${partSerial}`;

                      const offsetInput = row.querySelector(`.${propertyName}.offset input`);
                      offsetInput.setAttribute('name', name);
                      offsetInput.value = oldValues[name]?.toString() ?? '0';

                      const onOffsetChanged = ((propertyName, row, offsetInput) => {
                        return () => {
                          const base = parseInt(row.querySelector(`.${propertyName}.base`).textContent);
                          const offset = parseInt(offsetInput.value);
                          const total = isNaN(base) ? NaN : isNaN(offset) ? base : base + offset;

                          row.querySelector(`.${propertyName}.total`).textContent =
                              isNaN(total) ? '―' : total.toString();

                          let sum =
                              [...offsetDistributionTableBody.querySelectorAll(`.${propertyName}.offset input`)]
                                  .map(/** @param {HTMLInputElement} x */x => parseInt(x.value))
                                  .filter(x => !isNaN(x))
                                  .reduce((x, y) => x + y, 0);

                          const offsetSumNode =
                              offsetDistributionTableFooter.querySelector(`.${propertyName}.offset`);

                          if (offsetSumNode.textContent !== sum.toString()) {
                            offsetSumNode.textContent = sum.toString();
                            swordFragmentNumChanged();
                          }
                        };
                      })(propertyName, row, offsetInput);

                      offsetInput.addEventListener('input', () => onOffsetChanged());

                      functionsToSetupInput.push(onOffsetChanged);
                    }

                    offsetDistributionTableBody.appendChild(row);

                    partCount++;
                  }
              );

              functionsToSetupInput.forEach(f => f.call(null));
              swordFragmentNumChanged();

              offsetDistributionTable.dataset.partCount = partCount.toString();
            }

            mountHpOptionsUpdated();

            {
              /**
               * @param {HTMLInputElement} checkboxNode
               */
              function applyModifier(checkboxNode = null) {
                if (checkboxNode != null && !checkboxNode.classList.contains('is-modifier')) {
                  return;
                }

                const checkboxNodes =
                    checkboxNode != null
                        ? [checkboxNode]
                        : [...document.querySelectorAll('.reinforcement-items .using-items input[type="checkbox"].to-use.is-modifier')];

                checkboxNodes.forEach(
                    checkbox => {
                      if (checkbox.hasAttribute('data-hp-offset')) {
                        const offset = checkbox.dataset.hpOffset;

                        document.querySelectorAll(`#source-status-table tbody tr[data-part-serial="${checkbox.dataset.partSerial}"] td.hp`).forEach(
                            td => {
                              const offsetNode = td.querySelector(`.offset.offset-of-${checkbox.dataset.hpOffsetName}`);
                              offsetNode.dataset.offset = checkbox.checked ? offset : '';
                            }
                        );
                      }

                      if (checkbox.hasAttribute('data-mobility-offset')) {
                        const offset = checkbox.dataset.mobilityOffset;

                        document.querySelectorAll('#section-common > .status .mobility .offset').forEach(
                            offsetNode => {
                              offsetNode.textContent = checkbox.checked ? offset : '';
                            }
                        );
                      }

                      if (checkbox.classList.contains('remove-weakness')) {
                        document.querySelector('#section-common > .status').classList.toggle(
                            'remove-weakness',
                            checkbox.checked
                        );

                        refreshAttributeSelector();
                      }
                    }
                );
              }

              function refreshAttributeSelector() {
                const weakness =
                    document.querySelector('#section-common > .status').classList.contains('remove-weakness')
                        ? ''
                        : document.querySelector('[data-related-field="weakness"]').textContent.trim();

                const selector =
                    document.querySelector('.reinforcement-items .using-items .resistance-attribute-selector');

                selector.querySelectorAll('option').forEach(
                    option => {
                      const attribute = option.textContent.trim();

                      if (attribute === '') {
                        return;
                      }

                      if (weakness.includes(attribute)) {
                        option.setAttribute('disabled', '');
                      } else {
                        option.removeAttribute('disabled');
                      }
                    }
                );
              }

              /**
               * @param {HTMLElement} itemNode
               */
              function refreshItemCount(itemNode = null) {
                const sectionNodes =
                    itemNode != null
                        ? [itemNode.closest('.part-restriction-group')]
                        : [...document.querySelectorAll('.reinforcement-items .using-items .part-restriction-group')];

                const countOfRequirementAllPartsItem =
                    document.querySelectorAll('.reinforcement-items .using-items .part-restriction-group[data-name="全部位必須"] input.to-use[type="checkbox"]:checked').length;

                sectionNodes.forEach(
                    sectionNode => {
                      const headline = sectionNode.querySelector('h4');

                      if (headline.dataset.content === "全部位必須") {
                        return;
                      }

                      const currentCount =
                          sectionNode.querySelectorAll('input.to-use[type="checkbox"]:checked').length +
                          countOfRequirementAllPartsItem;

                      headline.querySelector('.count .current').textContent = currentCount.toString();

                      const maxCount = parseInt(headline.querySelector('.count .max').textContent.trim());

                      headline.classList.toggle('item-overflow', currentCount > maxCount);
                    }
                );
              }

              /** @var {Object<string, boolean|string>} */
              const oldValues = {};

              document.querySelectorAll('#loaded-data [name]').forEach(
                  x => {
                    const name = x.getAttribute('name');
                    if (name.startsWith('golemReinforcement_')) {
                      const value = x.getAttribute('value');
                      oldValues[name] = value === 'on' ? true : value;
                    }
                  }
              );

              const isSinglePart = document.querySelector('[name="partsNum"]').value === '1';
              const itemGrade = document.querySelector('[name="reinforcementItemGrade"]').value.trim();

              /** @var {Object<string, Array<{itemName: string, fieldName: string, abilityName: {html: string, suffix: string}, price: string, hasPrerequisiteItem: boolean, additionalField?: {name: string, contentHtml: string}}>>} */
              const itemsByPartRestriction = {};

              /** @var {string[]} */
              const partRestrictions =
                  document.querySelector('[name="parts"]').value.split(/[/／]/)
                      .map(x => x.replace(/×\s*\d+\s*$/, '').trim())
                      .filter(x => x !== '');

              document.querySelectorAll('.reinforcement-items .items dd.item.supported[data-item-name]').forEach(
                  x => {
                    const itemName = x.dataset.itemName;
                    const fieldName = x.dataset.fieldName;

                    const hasPrerequisiteItem =
                        (prerequisiteItem => prerequisiteItem != null && prerequisiteItem !== '')(
                            x.previousElementSibling.dataset.prerequisiteItem
                        );

                    const abilityNode = x.querySelector('dd.ability');
                    const abilityNameHtml = abilityNode.innerHTML;
                    const abilityNameSuffix = abilityNode.dataset.suffix;

                    const price = x.querySelector('[data-related-field$="_price"]').textContent;

                    const partRestriction =
                        isSinglePart
                            ? "任意部位"
                            : (partRestrictionNode => {
                              if (partRestrictionNode.querySelector('.requirement-all-parts') != null) {
                                return "全部位必須";
                              }

                              const partRestriction =
                                  partRestrictionNode.querySelector('[data-related-field$="_partRestriction"]')
                                      .textContent
                                      .trim()
                                      .replace(/\s*のみ\s*$/, '');

                              return partRestriction !== '' ? partRestriction : "任意部位";
                            })(x.querySelector('dd.part-restriction'));

                    const additionalFieldName =
                        x.querySelector('dt.additional-field')?.textContent.trim();

                    const additionalFieldContentHtml =
                        x.querySelector('dd.additional-field [data-related-field]')?.innerHTML;

                    const item = {
                      itemName,
                      fieldName,
                      abilityName: {
                        html: abilityNameHtml,
                        suffix: abilityNameSuffix,
                      },
                      price,
                      hasPrerequisiteItem
                    };

                    if (additionalFieldName != null && additionalFieldContentHtml != null) {
                      item['additionalField'] = {
                        name: additionalFieldName,
                        contentHtml: additionalFieldContentHtml
                      };
                    }

                    if (!(partRestriction in itemsByPartRestriction)) {
                      itemsByPartRestriction[partRestriction] = [];

                      if (
                          partRestriction !== "任意部位" &&
                          partRestriction !== "全部位必須" &&
                          !partRestrictions.includes(partRestriction)
                      ) {
                        partRestrictions.push(partRestriction);
                      }
                    }

                    itemsByPartRestriction[partRestriction].push(item);
                  }
              );

              if (partRestrictions.length > 0) {
                if (itemsByPartRestriction["任意部位"] != null) {
                  itemsByPartRestriction["任意部位"].reverse().forEach(
                      item => partRestrictions.forEach(
                          partName => {
                            if (!(partName in itemsByPartRestriction)) {
                              itemsByPartRestriction[partName] = [];
                            }

                            itemsByPartRestriction[partName].unshift(item);
                          }
                      )
                  );
                }

                partRestrictions.push("全部位必須");
              } else {
                partRestrictions.push("任意部位");

                if (!("任意部位" in itemsByPartRestriction)) {
                  itemsByPartRestriction["任意部位"] = [];
                }

                if (itemsByPartRestriction["全部位必須"] != null) {
                  itemsByPartRestriction["任意部位"].push(...itemsByPartRestriction["全部位必須"]);
                }
              }

              const usingItems = document.querySelector('.reinforcement-items section.using-items');
              usingItems.innerHTML = '';

              const templateOfSection = document.getElementById('template-of-part-restriction-group');
              const templateOfItem = document.getElementById('template-of-using-item');

              /** @var {string[]} */
              const partNames = [];
              for (const partName of document.querySelector('[data-related-field="parts"]').textContent.trim().split(/[\/／]/)) {
                const m = partName.match(/×(\d+)$/);

                if (m == null) {
                  partNames.push(partName);
                } else {
                  for (let i = 0; i < parseInt(m[1]); i++) {
                    partNames.push(partName.replace(/×\d+$/, '') + String.fromCharCode('A'.charCodeAt(0) + i));
                  }
                }
              }

              if (partRestrictions.includes("任意部位")) {
                partNames.unshift("任意部位");
              }

              if (partRestrictions.includes("全部位必須")) {
                partNames.push("全部位必須");
              }

              partNames.forEach(
                  (partName, partIndex) => {
                    const partRestriction = partName.replace(/[A-Z]$/, '');

                    if (
                        itemsByPartRestriction[partRestriction] == null ||
                        itemsByPartRestriction[partRestriction].length === 0
                    ) {
                      return;
                    }

                    const section = templateOfSection.content.firstElementChild.cloneNode(true);
                    section.dataset.name = partName;

                    const headline = section.querySelector('.part-restriction');
                    headline.querySelector('.text').textContent = partName;
                    headline.querySelector('.count .max').textContent = source['reinforcementItemMaxCount'] ?? '';
                    headline.dataset.content = partName;

                    const list = section.querySelector('.using-items');

                    for (const item of itemsByPartRestriction[partRestriction]) {
                      const itemNode = templateOfItem.content.firstElementChild.cloneNode(true);
                      itemNode.classList.toggle('has-prerequisite-item', item.hasPrerequisiteItem);
                      itemNode.querySelector('.item-name').innerHTML = item.itemName;
                      itemNode.querySelector('.item-grade').textContent = itemGrade;
                      itemNode.querySelector('.item-price').textContent = item.price;

                      const abilityNameNode = itemNode.querySelector('.ability-name');
                      abilityNameNode.innerHTML = item.abilityName.html;
                      abilityNameNode.appendChild(document.createTextNode(item.abilityName.suffix));

                      const abilityDetailsNode = itemNode.querySelector('.ability-details');
                      if (item.additionalField != null) {
                        abilityDetailsNode.dataset.kind = item.additionalField.name;
                        abilityDetailsNode.innerHTML = item.additionalField.contentHtml;

                        const detailsLabel = document.createElement('span');
                        detailsLabel.classList.add('details-label');
                        abilityDetailsNode.prepend(detailsLabel);
                      } else {
                        abilityDetailsNode.removeAttribute('data-kind');
                        abilityDetailsNode.textContent = '';
                      }

                      if (item.itemName === "石英の途絶") {
                        const label = document.createElement('label');
                        label.classList.add('select-attribute');
                        label.textContent = "耐性を得る属性：";

                        {
                          const name = 'golemReinforcement_quartzDisruption_attribute';

                          const selector = document.createElement('select');
                          selector.setAttribute('name', name);
                          selector.classList.add('resistance-attribute-selector');

                          for (const attribute of ['', '土', '水・氷', '炎', '風', '雷', '純エネルギー']) {
                            const option = document.createElement('option');
                            option.textContent = attribute;
                            selector.appendChild(option);
                          }

                          if (oldValues[name] != null) {
                            const index = [...selector.options].map(x => x.value).indexOf(oldValues[name]);

                            if (index >= 0) {
                              selector.selectedIndex = index;
                            }
                          }

                          label.appendChild(selector);
                        }

                        itemNode.appendChild(label);
                      }

                      {
                        const name =
                            `golemReinforcement_${item.fieldName}_part${partName !== "全部位必須" ? partIndex + 1 : 'All'}_using`;

                        const checkboxToUse = itemNode.querySelector('.to-use[type="checkbox"]');
                        checkboxToUse.setAttribute('name', name);
                        checkboxToUse.dataset.partSerial = (partIndex + 1).toString();

                        switch (item.fieldName) {
                          case 'garnetEnergy':
                            checkboxToUse.classList.add('is-modifier');
                            checkboxToUse.dataset.hpOffsetName = 'garnet-energy';
                            break;
                          case 'garnetLife':
                            checkboxToUse.classList.add('is-modifier');
                            checkboxToUse.dataset.hpOffsetName = 'garnet-life';
                            break;
                          case 'hematite':
                            checkboxToUse.classList.add('is-modifier');
                            checkboxToUse.dataset.mobilityOffset = '5';
                            break;
                          case 'moonstone':
                            checkboxToUse.classList.add('is-modifier', 'remove-weakness');
                            break;
                        }

                        if (checkboxToUse.hasAttribute('data-hp-offset-name')) {
                          let offset;

                          switch (itemGrade) {
                            case '小':
                              offset = 5;
                              break;
                            case '中':
                              offset = 10;
                              break;
                            case '大':
                              offset = 15;
                              break;
                            case '極大':
                              offset = 20;
                              break;
                          }

                          if (offset != null) {
                            checkboxToUse.dataset.hpOffset = offset.toString();
                          }
                        }

                        checkboxToUse.addEventListener(
                            'input',
                            () => {
                              applyModifier(checkboxToUse);
                              refreshItemCount(
                                  partName !== "全部位必須"
                                      ? itemNode
                                      : null
                              );
                            }
                        );

                        if (oldValues[name]) {
                          checkboxToUse.checked = true;
                        }
                      }

                      list.appendChild(itemNode);
                    }

                    usingItems.appendChild(section);
                  }
              );

              applyModifier();
              refreshItemCount();
            }

            {
              const sourceLootTable = document.querySelector('#source-loot-table');

              sourceLootTable.innerHTML = '';

              /** @var {HTMLTemplateElement} */
              const rowTemplate = document.getElementById('template-of-source-loot-table-row');

              for (let i = 1; i <= lootsNum; i++) {
                const range = source[`loots${i}Num`] ?? '';
                const item = source[`loots${i}Item`] ?? '';

                if (range === '' && item === '') {
                  continue;
                }

                const rangeNode = rowTemplate.content.querySelector('.range').cloneNode(true);
                rangeNode.textContent = range;
                sourceLootTable.appendChild(rangeNode);

                const contentNode = rowTemplate.content.querySelector('.content').cloneNode(true);
                contentNode.textContent = item;
                sourceLootTable.appendChild(contentNode);
              }
            }

            document.querySelectorAll('.mount-equipments dl.parts input[name]').forEach(
                input => input.dispatchEvent(new Event('input'))
            );
          }
      );
}
function individualizationModeChanged() {
  const individualizationCheckbox = document.querySelector('.individualization-area input[name="individualization"]');
  const sourceUrlInput = document.querySelector('.individualization-area input[name="sourceMonsterUrl"]');
  const form = document.getElementById('monster');

  if (!individualizationCheckbox.checked) {
    form.classList.remove('individualization');
    sourceUrlInput.removeEventListener('change', individualizationSourceUrlChanged);
    sourceUrlInput.setAttribute('readonly', '');
    return;
  }

  form.classList.add('individualization');
  sourceUrlInput.removeAttribute('readonly');
  sourceUrlInput.addEventListener('change', individualizationSourceUrlChanged);
  sourceUrlInput.dispatchEvent(new Event('change'));

  mountHpOptionsUpdated();
}
function mountHpOptionsUpdated() {
  let offsetTotal = 0;

  document.querySelectorAll('.mount-hp-options input[type="checkbox"][data-hp]').forEach(
      checkbox => {
        if (!checkbox.checked) {
          return;
        }

        offsetTotal += parseInt(checkbox.dataset.hp);
      }
  );

  document.querySelectorAll('#source-status-table .hp .hp-option-offset').forEach(
      node => node.dataset.offset = offsetTotal.toString()
  );
}
document.querySelectorAll('[data-related-field]').forEach(
    node => {
      const relatedFieldName = node.dataset.relatedField;
      const relatedFieldNode = document.querySelector(`#monster [name="${relatedFieldName}"]`);

      if (relatedFieldNode == null) {
        console.warn(`Field '${relatedFieldName}' is not found.`);
        return;
      }

      relatedFieldNode.addEventListener(
          'input',
          e => {
            if (e.target instanceof HTMLTextAreaElement) {
              node.innerHTML = e.target.value
                  .replaceAll(/&/g, '&amp;')
                  .replaceAll(/</g, '&lt;')
                  .replaceAll(/>/g, '&gt;')
                  .replaceAll(/"/g, '&quot;')
                  .replaceAll(/'/g, '&#39;')
                  .replaceAll(/\n/g, '<br>');
            } else {
              node.textContent =
                  e.target.getAttribute('type') === 'number'
                      ? commify(e.target.value)
                      : e.target.value;
            }
          }
      );
    }
);
function switchHabitatReplacement() {
  const checkbox = document.querySelector('[name="habitatReplacementEnabled"]');
  const textField = document.querySelector('[name="habitatReplacement"]');

  if (checkbox.checked) {
    textField.removeAttribute('disabled');
  } else {
    textField.setAttribute('disabled', '');
  }
}
function switchLoots() {
  const checkbox = document.querySelector('[name="disableLoots"]');
  checkbox.closest('.box').classList.toggle('loots-disabled', checkbox.checked);
}
function swordFragmentNumChanged() {
  const fragmentNumInput = document.querySelector('[name="swordFragmentNum"]');
  const fragmentNum = fragmentNumInput.value !== '' ? parseInt(fragmentNumInput.value) : 0;
  const resistanceOffset = Math.min(Math.ceil((fragmentNum) / 5), 4);

  fragmentNumInput.closest('.box').dataset.swordFragmentNum = fragmentNum.toString();

  const hpOffset = fragmentNum * 5;
  const mpOffset = fragmentNum * 1;

  const summaryNode = document.querySelector('.sword-fragment-box label.num .effect-summary');
  summaryNode.querySelector('.hp-offset .value').textContent = hpOffset > 0 ? hpOffset.toString() : '';
  summaryNode.querySelector('.mp-offset .value').textContent = mpOffset > 0 ? mpOffset.toString() : '';
  summaryNode.querySelector('.vit-resistance-offset .value').textContent = resistanceOffset > 0 ? resistanceOffset.toString() : '';
  summaryNode.querySelector('.mnd-resistance-offset .value').textContent = resistanceOffset > 0 ? resistanceOffset.toString() : '';

  document.querySelectorAll('#section-common > .status dl:is(.vit-resistance, .mnd-resistance) .offset-by-sword-fragment').forEach(
      x => x.textContent = resistanceOffset > 0 ? resistanceOffset.toString() : ''
  );

  const offsetDistribution = document.querySelector('.sword-fragment-box .offset-distribution');

  const hasSinglePart = offsetDistribution.querySelectorAll('tbody tr').length === 1;

  const summaryRow = offsetDistribution.querySelector('tfoot.sum tr');

  for (const [className, expectedValue] of [['hp', hpOffset], ['mp', mpOffset]]) {
    const cell = summaryRow.querySelector(`.${className}.offset`);

    if (hasSinglePart) {
      const input = offsetDistribution.querySelector(`tbody .${className} input`);

      if (input.value !== expectedValue.toString()) {
        input.value = expectedValue.toString();
        input.dispatchEvent(new Event('input'));
      }

      cell.textContent = expectedValue.toString();
    }

    cell.dataset.expected = expectedValue.toString();

    const current = parseInt(cell.textContent.trim());
    cell.classList.toggle('deficient', !isNaN(current) && current < expectedValue);
    cell.classList.toggle('excess', !isNaN(current) && current > expectedValue);
  }
}
document.querySelector('[name="swordFragmentNum"]').addEventListener('input', () => swordFragmentNumChanged());
