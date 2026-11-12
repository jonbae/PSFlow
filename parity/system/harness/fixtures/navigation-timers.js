// Standalone platform fixture: a zero timer must stay held across navigation.
window.receipts = [];
const observer = new ResizeObserver(() => { receipts.push('resize'); observer.disconnect(); });
observer.observe(document.querySelector('#target'));
setTimeout(() => receipts.push('timer'), 0);
