(() => {
  'use strict';
  const KEY = 'osnova.diagnostic-intake.v1';
  // Enable only after approved document versions and a protected submission service are configured.
  const legalDocumentsReady = true;
  const submissionReady = true;
  const questions = [
    {title:'Чем вы занимаетесь в настоящее время?',section:'Немного о вас',options:['Управляю собственным бизнесом / совладелец бизнеса','Занимаю руководящую должность','Являюсь сотрудником','Развиваю частную практику или собственные проекты','Занимаюсь семьёй, детьми и личными проектами','Сейчас не веду профессиональную деятельность']},
    {title:'Сколько сотрудников работает в вашей компании?',section:'Немного о вас',options:['Работаю самостоятельно','2–10 человек','11–30 человек','31–100 человек','Более 100 человек','Не занимаюсь бизнесом / вопрос не применим']},
    {title:'Что сейчас для вас наиболее актуально?',section:'Ваша ситуация',options:['Выйти на следующий уровень дохода или бизнеса','Решить повторяющуюся проблему','Снизить стресс, восстановить энергию','Изменить ситуацию в отношениях','Обрести ясность, цели и мотивацию','Интересно узнать о методе']},
    {title:'Насколько сильно эта ситуация влияет на вашу жизнь?',section:'Ваша ситуация',options:['Существенно ограничивает меня','Заметно мешает, хочу разобраться','Есть, но пока не критична','Скорее интересуюсь темой']},
    {title:'Что вы уже предпринимали для решения вопроса?',section:'Ваш опыт',options:['Обращался(ась) к психологам или другим специалистам','Пробовал(а) самостоятельно изменить ситуацию','Менял(а) обстоятельства, команду или стратегию','Пока ничего не предпринимал(а)']},
    {title:'Когда вы хотели бы начать работу над запросом?',section:'Следующий шаг',options:['В ближайшие 7 дней','В течение месяца','В следующие 1–3 месяца','Пока не планирую']},
    {title:'Какой следующий шаг вы бы предпочли после диагностики?',section:'Следующий шаг',options:['Начать работу над изменением ситуации','Получить индивидуальный маршрут для последовательных изменений','Сначала изучить возможные способы решения','Пока только разобраться в причинах происходящего']}
  ];
  let submitting=false, submitted=false;
  const empty = () => ({version:1,step:0,answers:questions.map(()=>[]),name:'',contact:'',consent:false});
  let state=empty(), persistent=true, opener=null, resetPending=false;
  try {
    const draft=JSON.parse(localStorage.getItem(KEY));
    if(draft?.version===1){
      state.step=Number.isInteger(draft.step)?Math.max(0,Math.min(7,draft.step)):0;
      state.answers=questions.map((q,i)=>Array.isArray(draft.answers?.[i])?draft.answers[i].filter(v=>Number.isInteger(v)&&v>=0&&v<q.options.length).slice(0,1):[]);
      state.name=typeof draft.name==='string'?draft.name.slice(0,100):'';
      state.contact=typeof draft.contact==='string'?draft.contact.slice(0,120):'';
      // Answers are resumable; consent must be given again and is never restored from a draft.
      if(Object.hasOwn(draft,'consent')){delete draft.consent;localStorage.setItem(KEY,JSON.stringify(draft));}
    }
  } catch {persistent=false;}
  const escape = value => String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  // Seven vector illustrations follow the approved concept sheet. Step 1 keeps its original CSS orbits.
  const artDot=(x,y,r=3,dim=false)=>`<circle class="intake-art-dot${dim?' is-dim':''}" cx="${x}" cy="${y}" r="${r}"/>`;
  const timeTicks=[205,235,265,295,325].map(a=>{
    const t=a*Math.PI/180;
    return `<path d="M${110+69*Math.sin(t)} ${100-69*Math.cos(t)} L${110+77*Math.sin(t)} ${100-77*Math.cos(t)}"/>`;
  }).join('');
  const contour='M110 21 C131 19 142 40 161 49 C181 59 191 70 188 91 C186 113 178 139 161 151 C145 162 118 171 99 166 C80 161 65 151 49 143 C30 132 25 111 30 93 C34 77 46 67 60 58 C79 46 86 25 110 21Z';
  const illustrations=[null,
    `<g class="intake-art-line intake-art-team"><path opacity=".65" d="M24 151 C25 133 31 128 47 122 C58 118 65 114 65 105 L65 99 C49 94 46 72 50 59 C54 43 72 40 81 52 C92 65 88 88 77 98 L77 106 C77 115 84 119 94 123"/><path opacity=".65" d="M126 123 C136 119 143 115 143 106 L143 98 C132 88 128 65 139 52 C148 40 166 43 170 59 C174 72 171 94 155 99 L155 105 C155 114 162 118 173 122 C189 128 195 133 196 151"/><path d="M49 165 C53 140 60 132 81 124 C95 118 99 115 99 101 L99 98 C87 91 83 74 84 61 C84 41 94 29 110 29 C126 29 136 41 136 61 C137 74 133 91 121 98 L121 101 C121 115 125 118 139 124 C160 132 167 140 171 165"/><path opacity=".4" d="M83 124 Q110 139 137 124"/></g>${artDot(110,133,2.4)}`,
    `<g class="intake-art-line intake-art-focus"><path d="M88 54 A51 51 0 0 1 132 54 M156 78 A51 51 0 0 1 156 122 M132 146 A51 51 0 0 1 88 146 M64 122 A51 51 0 0 1 64 78"/></g>${artDot(110,100,3.1)}`,
    `<g class="intake-art-line intake-art-influence">${[1,.82,.65,.49,.34,.2].map((scale,i)=>`<path d="${contour}" transform="translate(${110*(1-scale)+i*1.1} ${100*(1-scale)+i*.6}) scale(${scale})" opacity="${.48+i*.09}"/>`).join('')}</g>${artDot(117,102,2.7)}`,
    `<g class="intake-art-line intake-art-experience"><path d="M24 163 C52 137 70 137 93 116 S145 89 189 38"/><path opacity=".45" d="M24 163 C70 162 141 122 189 38"/><path opacity=".3" stroke-dasharray=".2 3.2" d="M24 163 C94 181 169 123 189 38"/><path opacity=".4" stroke-dasharray=".2 3.2" d="M24 163 C68 140 165 138 189 38"/></g>${[[24,163],[65,134],[105,107],[150,77],[189,38]].map(([x,y],i)=>artDot(x,y,i===4?3.3:2.4)).join('')}`,
    `<g class="intake-art-line intake-art-time"><path d="M108 172 A72 72 0 1 1 168 57"/><path opacity=".4" stroke-dasharray=".2 3.3" d="M168 57 A72 72 0 0 1 108 172"/>${timeTicks}</g>${artDot(168,57,3.2)}`,
    `<g class="intake-art-line intake-art-route"><path d="M21 127 C52 120 74 115 92 111 C122 105 144 64 191 43"/><path opacity=".45" d="M92 111 C134 108 142 139 159 149"/><path opacity=".35" stroke-dasharray=".2 3.2" d="M159 149 Q174 161 189 168"/></g>${artDot(191,43,3.4)}${artDot(189,168,2.6,true)}`,
    `<g class="intake-art-line intake-art-connection"><path d="M30 100 C69 48 136 150 191 110 C151 169 87 42 30 100Z"/><path opacity=".5" d="M30 100 C77 76 135 124 191 110"/><path opacity=".4" stroke-dasharray=".2 3" d="M30 100 C4 51 63 65 110 105 C154 146 209 151 191 110 C177 68 155 67 110 105 C68 142 8 134 30 100Z"/></g>${artDot(30,100,3.7)}${artDot(191,110,3.1)}`
  ];
  const dialog=document.createElement('dialog');
  dialog.id='intake-dialog';dialog.className='intake-dialog';
  dialog.setAttribute('aria-labelledby','intake-title');
  dialog.innerHTML=`<div class="intake-layout"><aside class="intake-aside"><img class="intake-brand" src="assets/osnova-logo-hero.svg" alt="ОСНОВА" width="145" height="22"><h2 id="intake-title">Анкета для записи на <em>бесплатную первичную диагностику</em></h2><div class="intake-orbit" aria-hidden="true"><span></span></div><p class="intake-save" id="intake-save"></p></aside><div class="intake-main"><div class="intake-top"><p class="intake-kicker" id="intake-kicker"></p><button type="button" class="intake-close" aria-label="Закрыть анкету">×</button></div><div class="intake-progress-row"><span id="intake-counter"></span><span id="intake-percent"></span></div><div class="intake-progress" role="progressbar" aria-label="Прогресс заполнения анкеты" aria-valuemin="0" aria-valuemax="8"><span></span></div><form id="intake-form" class="intake-form" novalidate data-private data-clarity-mask="true" data-hj-suppress><div id="intake-content"></div><p class="intake-status" id="intake-status" role="status" aria-live="polite"></p><div class="intake-navigation"><button type="button" class="intake-back">← Назад</button><button type="submit" class="intake-next"></button></div></form><div class="intake-bottom"><span id="intake-draft-note"></span><button type="button" class="intake-reset">Очистить анкету</button></div><div class="intake-reset-confirm" hidden><span>Удалить все ответы?</span><button type="button" data-reset-confirm>Удалить</button><button type="button" data-reset-cancel>Отмена</button></div><div class="intake-legal-content" id="intake-legal-content" data-private data-clarity-mask="true" data-hj-suppress hidden></div></div></div>`;
  document.body.append(dialog);
  const honeypot=document.createElement('input');
  honeypot.type='text';honeypot.name='website';honeypot.hidden=true;honeypot.tabIndex=-1;honeypot.autocomplete='off';
  honeypot.setAttribute('data-osnova-honeypot','');
  dialog.querySelector('form').append(honeypot);
  const $=id=>dialog.querySelector('#'+id);
  const status=$('intake-status');
  function storageMessage(){
    $('intake-save').textContent=persistent?'Можно прерваться. Ответы сохраняются в этом браузере на вашем устройстве.':'Черновик доступен до закрытия этой страницы: браузер не разрешает сохранение.';
    $('intake-draft-note').textContent=persistent?'Черновик сохраняется автоматически':'Ответы сохранены только на этой странице';
  }
  function updateProgress(){
    const count=state.answers.filter(v=>v.length).length+(state.name.trim()&&state.contact.trim()?1:0);
    const progress=dialog.querySelector('.intake-progress');
    progress.setAttribute('aria-valuenow',String(count));
    progress.setAttribute('aria-valuetext',`Заполнено ${count} из 8 шагов`);
    progress.firstElementChild.style.width=`${count/8*100}%`;
  }
  function save(){
    if(submitted)return;
    const {consent,...draft}=state;
    try{localStorage.setItem(KEY,JSON.stringify({...draft,updatedAt:Date.now()}));persistent=true;}
    catch{persistent=false;}
    storageMessage();
  }
  function feedback(text,info=false){status.textContent=text;status.classList.toggle('is-info',info);}
  function render(focus=false){
    const q=questions[state.step],contacts=!q;
    const art=dialog.querySelector('.intake-orbit');
    art.classList.toggle('is-illustrated',state.step>0);
    art.dataset.step=String(state.step+1);
    art.innerHTML=state.step===0?'<span></span>':`<svg class="intake-art" viewBox="0 0 220 200" fill="none" aria-hidden="true" focusable="false">${illustrations[state.step]}</svg>`;
    $('intake-kicker').textContent=q?q.section:'Контактные данные';
    $('intake-counter').textContent=contacts?'Контакты · шаг 8 из 8':`Вопрос ${state.step+1} из 7`;
    $('intake-percent').textContent=`${String(state.step+1).padStart(2,'0')} / 08`;
    updateProgress();
    $('intake-content').innerHTML=q?`<fieldset class="intake-fieldset"><legend id="intake-question" tabindex="-1">${escape(q.title)}</legend><p class="intake-hint">Выберите один вариант</p><div class="intake-options">${q.options.map((text,i)=>`<label class="intake-option"><input type="radio" name="intake-question-${state.step}" value="${i}" ${state.answers[state.step].includes(i)?'checked':''}><span>${escape(text)}</span></label>`).join('')}</div></fieldset>`:`<fieldset class="intake-fieldset"><legend id="intake-question" tabindex="-1">Как с вами связаться?</legend><div class="intake-fields"><label><span class="intake-field-label">Как к вам обращаться?</span><input class="intake-input" id="intake-name" name="name" autocomplete="given-name" maxlength="100" placeholder="Ваше имя" value="${escape(state.name)}" required></label><label><span class="intake-field-label">Ваш Telegram или номер телефона</span><input class="intake-input" id="intake-contact" name="contact" autocomplete="off" autocapitalize="off" spellcheck="false" maxlength="120" placeholder="@username или +7 999 123-45-67" value="${escape(state.contact)}" required></label></div><div class="intake-consent"><input id="intake-consent" form="intake-form" name="personalDataConsent" type="checkbox" required ${state.consent?'checked':''} aria-labelledby="intake-consent-label"><span id="intake-consent-label">Я даю согласие на обработку моих персональных данных в соответствии с <a class="intake-legal-link" href="consent.html" target="_blank" rel="noopener noreferrer">Согласием на обработку персональных данных</a> и ознакомлен(а) с <a class="intake-legal-link" href="privacy.html" target="_blank" rel="noopener noreferrer">Политикой обработки персональных данных</a>.</span></div><p class="intake-preview-note">Для записи можно <a href="https://t.me/os_nova_mind" target="_blank" rel="noopener noreferrer" data-intake-direct>перейти в Telegram</a>.</p></fieldset>`;
    const legalContent=$('intake-legal-content');
    legalContent.replaceChildren();
    if(contacts){
      for(const element of $('intake-content').querySelectorAll('.intake-consent,.intake-preview-note'))legalContent.append(element);
    }
    legalContent.hidden=!contacts;
    dialog.querySelector('.intake-back').disabled=state.step===0;
    const next=dialog.querySelector('.intake-next');
    next.innerHTML=contacts?'Отправить заявку на бесплатную диагностику':'Далее <span aria-hidden="true">→</span>';
    next.classList.toggle('is-submit',contacts);
    next.disabled=contacts&&(!state.consent||!legalDocumentsReady||!submissionReady);
    feedback('');storageMessage();
    if(focus)$('intake-question').focus({preventScroll:true});
  }
  function open(trigger){
    if(submitting)return;
    if(submitted){submitted=false;state=empty();}
    opener=trigger||document.activeElement;
    state.consent=false;
    document.getElementById('mobile-menu')?.close();
    render();
    if(!dialog.open)dialog.showModal();
    document.documentElement.classList.add('intake-open');
    $('intake-question').focus({preventScroll:true});
  }
  window.osnovaIntake={open};
  document.querySelectorAll('a[href="https://t.me/os_nova_mind"], [data-intake]').forEach(el=>{
    if(dialog.contains(el))return;
    el.setAttribute('aria-haspopup','dialog');el.setAttribute('aria-controls',dialog.id);
  });
  document.addEventListener('click',event=>{
    const trigger=event.target.closest('[data-intake],a[href="https://t.me/os_nova_mind"]');
    if(!trigger||dialog.contains(trigger))return;
    event.preventDefault();event.stopImmediatePropagation();open(trigger);
  },true);
  dialog.querySelector('.intake-close').addEventListener('click',()=>dialog.close());
  dialog.addEventListener('close',()=>{save();document.documentElement.classList.remove('intake-open');opener?.focus({preventScroll:true});});
  dialog.addEventListener('click',event=>{
    if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}
  });
  dialog.addEventListener('input',event=>{
    if(event.target.id==='intake-name')state.name=event.target.value;
    else if(event.target.id==='intake-contact')state.contact=event.target.value;
    else return;
    event.target.removeAttribute('aria-invalid');feedback('');save();updateProgress();
  });
  dialog.addEventListener('change',event=>{
    if(event.target.id==='intake-consent'){state.consent=event.target.checked;dialog.querySelector('.intake-next').disabled=!state.consent||!legalDocumentsReady||!submissionReady;feedback('');return;}
    if(!event.target.matches('.intake-option input'))return;
    state.answers[state.step]=[Number(event.target.value)];
    feedback('');save();
    updateProgress();
  });
  dialog.querySelector('.intake-back').addEventListener('click',()=>{if(submitting||submitted)return;if(state.step>0){state.step--;save();render(true);}});
  dialog.querySelector('form').addEventListener('submit',event=>{
    event.preventDefault();
    if(state.step<7){
      if(!state.answers[state.step].length){feedback('Выберите ответ, чтобы продолжить.');dialog.querySelector('.intake-option input')?.focus();return;}
      state.step++;save();render(true);dialog.scrollTop=0;return;
    }
    if(!state.consent){$('intake-consent').focus();feedback('Для отправки потребуется ваше согласие на обработку персональных данных.');return;}
    if(!legalDocumentsReady||!submissionReady){feedback('Онлайн-отправка ещё не подключена. Заявка и согласие никуда не отправлены; для записи перейдите в Telegram.',true);return;}
    const missing=state.answers.findIndex(v=>!v.length);
    if(missing>=0){state.step=missing;save();render(true);feedback('Пожалуйста, ответьте на этот вопрос.');return;}
    for(const [key,label] of [['name','Укажите, как к вам обращаться.'],['contact','Укажите ваш Telegram или номер телефона.']]){
      if(!state[key].trim()){$('intake-'+key).setAttribute('aria-invalid','true');$('intake-'+key).focus();feedback(label);return;}
    }
    const contact=state.contact.trim();
    const validContact=/^@?[a-z][a-z0-9_]{4,31}$/i.test(contact)||/^(?:https?:\/\/)?t\.me\/[a-z][a-z0-9_]{4,31}\/?$/i.test(contact)||(/^\+?[\d\s().-]+$/.test(contact)&&contact.replace(/\D/g,'').length>=7&&contact.replace(/\D/g,'').length<=15);
    if(!validContact){$('intake-contact').setAttribute('aria-invalid','true');$('intake-contact').focus();feedback('Проверьте Telegram (@username) или номер телефона.');return;}
    if(!state.consent){$('intake-consent').focus();feedback('Для отправки потребуется согласие на обработку персональных данных.');return;}
    if(submitting||submitted)return;
    if(!window.OsnovaIntake){feedback('Не удалось подключиться к форме. Напишите нам в Telegram.',true);return;}
    save();submitting=true;
    const button=dialog.querySelector('.intake-next');
    button.disabled=true;dialog.querySelectorAll('input').forEach(el=>{el.disabled=true;});feedback('Отправляем…');
    const data={answers:state.answers.map((a,i)=>({id:'q'+(i+1),index:a[0],text:questions[i].options[a[0]]})),name:state.name.trim(),contact,consent:true};
    window.OsnovaIntake.submit(data).then(()=>{
      submitted=true;state=empty();
      try{localStorage.removeItem(KEY);}catch{}
      $('intake-content').replaceChildren();$('intake-legal-content').replaceChildren();
      dialog.querySelector('.intake-back').disabled=true;
      button.textContent='Заявка отправлена';
      feedback('Заявка отправлена. Мы свяжемся с вами в Telegram или по телефону.');
    }).catch(()=>feedback('Не получилось отправить. Ответы сохранены — попробуйте ещё раз или напишите нам в Telegram.',true))
      .finally(()=>{submitting=false;dialog.querySelectorAll('input').forEach(el=>{el.disabled=false;});button.disabled=submitted;});
  });
  const resetConfirm=dialog.querySelector('.intake-reset-confirm');
  dialog.querySelector('.intake-reset').addEventListener('click',()=>{resetPending=!resetPending;resetConfirm.hidden=!resetPending;});
  dialog.querySelector('[data-reset-cancel]').addEventListener('click',()=>{resetPending=false;resetConfirm.hidden=true;});
  dialog.querySelector('[data-reset-confirm]').addEventListener('click',()=>{if(submitting)return;submitted=false;state=empty();resetPending=false;resetConfirm.hidden=true;try{localStorage.removeItem(KEY);}catch{}render(true);dialog.scrollTop=0;});
  window.addEventListener('pagehide',save);
  render();
})();
