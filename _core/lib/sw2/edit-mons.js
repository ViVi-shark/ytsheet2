"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  nameSet();
  rewriteMountLevel();
  updatePartsAutomatically();
  updatePartList();
  selectInputCheck('taxa',form.taxa,'その他')
  checkKind();
  updateGolemReinforcementItemGrade(false);
  updateGolemReinforcementItemPartRestriction();
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
function nameSet(){
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
    "vit"        : copy        ? form[`status${copy}${lv}Vit`         ].value : '―',
    "mnd"        : copy        ? form[`status${copy}${lv}Mnd`         ].value : '―',
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
    if(form[`status${num}Style`].value || form[`status${num}Accuracy`].value || form[`status${num}AccuracyFix`].value || form[`status${num}Evasion`].value || form[`status${num}EvasionFix`].value || form[`status${num}Defense`].value || form[`status${num}Hp`].value || form[`status${num}Mp`].value){
      if (!force && !confirm(delConfirmText)) return false;
    }
    document.querySelectorAll("#status-table tbody").forEach(table => {
      table.deleteRow(-1);
    });
    num--;
    form.statusNum.value = num;
  }
  updatePartsAutomatically();
}
// ソート
let statusSortable = Sortable.create(document.querySelector('#status-table tbody'), {
  group: "status",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = statusSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Style"]`      ).setAttribute('name',`status${num}Style`);
        document.querySelector(`#${id} [name$="Accuracy"]`   ).setAttribute('name',`status${num}Accuracy`);
        document.querySelector(`#${id} [name$="AccuracyFix"]`).setAttribute('name',`status${num}AccuracyFix`);
        document.querySelector(`#${id} [name$="Damage"]`     ).setAttribute('name',`status${num}Damage`);
        document.querySelector(`#${id} [name$="Evasion"]`    ).setAttribute('name',`status${num}Evasion`);
        document.querySelector(`#${id} [name$="EvasionFix"]` ).setAttribute('name',`status${num}EvasionFix`);
        document.querySelector(`#${id} [name$="Defense"]`    ).setAttribute('name',`status${num}Defense`);
        document.querySelector(`#${id} [name$="Hp"]`         ).setAttribute('name',`status${num}Hp`);
        document.querySelector(`#${id} [name$="Mp"]`         ).setAttribute('name',`status${num}Mp`);
        document.querySelector(`#${id} [name$="Vit"]`         ).setAttribute('name',`status${num}Vit`);
        document.querySelector(`#${id} [name$="Mnd"]`         ).setAttribute('name',`status${num}Mnd`);
        document.querySelector(`#${id} [name$="Style"]`      ).setAttribute('oninput',`checkStyle(${num}); updatePartsAutomatically();`);
        document.querySelector(`#${id} [name$="Accuracy"]`   ).setAttribute('oninput',`calcAcc(${num})`);
        document.querySelector(`#${id} [name$="AccuracyFix"]`).setAttribute('oninput',`calcAccF(${num})`);
        document.querySelector(`#${id} [name$="Evasion"]`    ).setAttribute('oninput',`calcEva(${num})`);
        document.querySelector(`#${id} [name$="EvasionFix"]` ).setAttribute('oninput',`calcEvaF(${num})`);
        document.querySelector(`#${id} span[onclick]`        ).setAttribute('onclick',`addStatus(${num})`);
        num++;
      }
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
          if(document.getElementById(id)){
            document.querySelector(`#${id}-${lv} [name$="Accuracy"]`   ).setAttribute('name',`status${num}-${lv}Accuracy`);
            document.querySelector(`#${id}-${lv} [name$="Damage"]`     ).setAttribute('name',`status${num}-${lv}Damage`);
            document.querySelector(`#${id}-${lv} [name$="Evasion"]`    ).setAttribute('name',`status${num}-${lv}Evasion`);
            document.querySelector(`#${id}-${lv} [name$="Defense"]`    ).setAttribute('name',`status${num}-${lv}Defense`);
            document.querySelector(`#${id}-${lv} [name$="Hp"]`         ).setAttribute('name',`status${num}-${lv}Hp`);
            document.querySelector(`#${id}-${lv} [name$="Mp"]`         ).setAttribute('name',`status${num}-${lv}Mp`);
            document.querySelector(`#${id}-${lv} [name$="Vit"]`         ).setAttribute('name',`status${num}-${lv}Vit`);
            document.querySelector(`#${id}-${lv} [name$="Mnd"]`         ).setAttribute('name',`status${num}-${lv}Mnd`);
            document.querySelector(`#${id}-${lv} .name`).dataset.style = num;
            num++;
          }
        }
      }
    });
    rewriteMountLevel();
    updatePartsAutomatically();
  }
});
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
    partsNumInput.removeAttribute('readonly');
    partsNamesInput.removeAttribute('readonly');
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

  partsNumInput.setAttribute('readonly', '');
  partsNumInput.value = partCount.toString();
  partsNumInput.dispatchEvent(new Event('input'));

  partsNamesInput.setAttribute('readonly', '');
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
  const partsText = document.querySelector('input[name="parts"]').value.trim();

  const items =
      partsText
          .split(/[/／]/)
          .map(x => x.trim())
          .filter(x => x !== '')
          .map(
              part => /[*×]\d+$/.test(part)
                  ? `${part.replace(/[*×]\d+$/, '')}（すべて）`
                  : part
          );

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
    listNum.removeChild(listNum.lastElementChild);
    listItem.removeChild(listItem.lastElementChild);
    num--;
    form.lootsNum.value = num;
  }
}
// ソート
let lootsNumSortable = Sortable.create(document.querySelector('#loots-num'), {
  group: "loots",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = lootsNumSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} input`).setAttribute('name',`loots${num}Num`);
        num++;
      }
    }
  }
});
let lootsItemSortable = Sortable.create(document.querySelector('#loots-item'), {
  group: "loots",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = lootsItemSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} input`).setAttribute('name',`loots${num}Item`);
        num++;
      }
    }
  }
});

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
            console.log(source); // todo

            if (now !== lastSourceTimestamp) {
              return;
            }

            const isMount = source['mount']?.toString() === '1';
            const isGolem = source['golem']?.toString() === '1';

            document.querySelector('#group span.is-mount').dataset.isMount = isMount.toString();
            document.querySelector('#group span.is-golem').dataset.isGolem = isGolem.toString();

            ['description', 'skills'].forEach(
                key => {
                  if (source[key] == null) {
                    return;
                  }

                  source[key] = source[key]
                      .replaceAll(/&lt;/g, '<')
                      .replaceAll(/&gt;/g, '>')
                      .replaceAll(/<br>/gi, '\n');
                }
            );

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

              document.querySelectorAll('#loaded-part-equipment [name]').forEach(
                  x => oldValues[x.getAttribute('name')] = x.getAttribute('value')
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
                  /^(?:color(?:Base|Head)|forbidden$|hide$|palette|part\d+$|sheetDescription[SM]$|unit(?:Except)?Status|taxaSelect$)/i.test(key) || // このへんは無視する
                  key === 'individualization' || // 個別化チェックそのものは無視する
                  key === 'sourceMonsterUrl' || // 個別化の元データＵＲＬも無視する
                  ['characterName', 'tags'].includes(key) || // 名前・タグは上書き可能
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
                    control.checked = value === '1' || value === 1 || value === true;
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

            mountHpOptionsUpdated();

            {
              const sourceLootTable = document.querySelector('#source-loot-table');

              sourceLootTable.innerHTML = '';

              /** @var {HTMLTemplateElement} */
              const rowTemplate = document.getElementById('template-of-source-loot-table-row');

              for (let i = 1; i <= lootsNum; i++) {
                const rangeNode = rowTemplate.content.querySelector('.range').cloneNode(true);
                rangeNode.textContent = source[`loots${i}Num`] ?? '';
                sourceLootTable.appendChild(rangeNode);

                const contentNode = rowTemplate.content.querySelector('.content').cloneNode(true);
                contentNode.textContent = source[`loots${i}Item`] ?? '';
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
              node.textContent = e.target.value;
            }
          }
      );
    }
);
// document.querySelector('.individualization-area input[name="sourceMonsterUrl"]').value = 'http://localhost/ytsheet2/sw2.5/?id=W1xihL'; // todo: for DEBUG
// document.querySelector('.individualization-area input[name="sourceMonsterUrl"]').value = 'http://localhost/ytsheet2/sw2.5/?id=LPt9In'; // todo: for DEBUG
// document.querySelector('.individualization-area input[type="checkbox"][name="individualization"]').checked = true; // todo: for DEBUG
