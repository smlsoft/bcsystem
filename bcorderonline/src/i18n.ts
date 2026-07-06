import { computed, ref } from 'vue';

export type LanguageCode = 'en' | 'th' | 'lo' | 'zh-cn' | 'ja' | 'ko';

export type TranslationKey =
  | 'add_to_cart'
  | 'all_items'
  | 'back_to_edit'
  | 'basket'
  | 'call_staff'
  | 'call_staff_failed'
  | 'call_staff_success'
  | 'cart'
  | 'cart_items'
  | 'canceled_all'
  | 'canceled_items'
  | 'canceled_qty'
  | 'check_status'
  | 'close'
  | 'closed_order'
  | 'confirm_submit'
  | 'confirm_submit_body'
  | 'device'
  | 'edit'
  | 'edited_cart'
  | 'error_default'
  | 'drink_items'
  | 'food_items'
  | 'item_count'
  | 'items'
  | 'kitchen_done'
  | 'language'
  | 'loading_menu'
  | 'loading_products'
  | 'max_selected'
  | 'menu'
  | 'missing_options'
  | 'no_cart_items'
  | 'no_orders'
  | 'no_products'
  | 'no_qr_body'
  | 'no_qr_title'
  | 'not_found_order'
  | 'note'
  | 'open_order'
  | 'order_failed'
  | 'order_pending'
  | 'order_pending_detail'
  | 'ordered'
  | 'ordered_total'
  | 'orders'
  | 'pending_attempts'
  | 'pending_order'
  | 'pending_retry_hint'
  | 'quantity'
  | 'remaining_qty'
  | 'retry'
  | 'retry_submit'
  | 'save'
  | 'search'
  | 'search_food'
  | 'select'
  | 'select_max'
  | 'select_one'
  | 'served_all'
  | 'served_qty'
  | 'sent_order'
  | 'sent_order_detail'
  | 'session_failed_body'
  | 'session_failed_title'
  | 'sold_out'
  | 'stock_limit'
  | 'stock_limit_detail'
  | 'submit_order'
  | 'table'
  | 'table_order'
  | 'unknown_device'
  | 'updated_latest'
  | 'waiting_kitchen';

const storageKey = 'bcorderonline:language';

export const languageOptions: Array<{ code: LanguageCode; label: string; shortLabel: string }> = [
  { code: 'th', label: 'Thai', shortLabel: 'TH' },
  { code: 'en', label: 'English', shortLabel: 'EN' },
  { code: 'lo', label: 'Laos', shortLabel: 'LO' },
  { code: 'zh-cn', label: 'Chinese', shortLabel: 'CN' },
  { code: 'ja', label: 'Japan', shortLabel: 'JP' },
  { code: 'ko', label: 'Korea', shortLabel: 'KR' },
];

const localeByLanguage: Record<LanguageCode, string> = {
  en: 'en-US',
  th: 'th-TH',
  lo: 'lo-LA',
  'zh-cn': 'zh-CN',
  ja: 'ja-JP',
  ko: 'ko-KR',
};

const dictionaries: Record<'en' | 'th', Partial<Record<TranslationKey, string>>> = {
  en: {
    add_to_cart: 'Add to cart',
    all_items: 'All',
    back_to_edit: 'Back to edit',
    basket: 'Basket',
    call_staff: 'Call staff',
    call_staff_failed: 'Could not call staff',
    call_staff_success: 'Staff has been called',
    cart: 'Cart',
    cart_items: 'Items in cart',
    canceled_all: 'Canceled all {count}',
    canceled_items: 'Canceled',
    canceled_qty: 'Canceled {count}',
    check_status: 'Check status',
    close: 'Close',
    closed_order: 'Closed',
    confirm_submit: 'Confirm order',
    confirm_submit_body: 'Review the items, then send this order to the cashier and kitchen.',
    device: 'Device',
    edit: 'Edit',
    edited_cart: 'Item updated',
    error_default: 'Something went wrong',
    drink_items: 'Drinks',
    food_items: 'Food',
    item_count: 'items',
    items: 'items',
    kitchen_done: 'Kitchen done',
    language: 'Language',
    loading_menu: 'Loading menu',
    loading_products: 'Loading items',
    max_selected: 'Selection limit reached',
    menu: 'Menu',
    missing_options: 'Please complete the options',
    no_cart_items: 'Your cart is empty',
    no_orders: 'No sent orders yet',
    no_products: 'No products found',
    no_qr_body: 'Please scan the table QR again.',
    no_qr_title: 'Order QR not found',
    not_found_order: 'This order is not visible yet',
    note: 'Note',
    open_order: 'Open',
    order_failed: 'Order has not been sent',
    order_pending: 'There is a pending order',
    order_pending_detail: 'Please check or resend the pending order before editing the cart.',
    ordered: 'Ordered',
    ordered_total: 'Total ordered',
    orders: 'Orders',
    pending_attempts: 'attempts',
    pending_order: 'Pending order',
    pending_retry_hint: 'You can resend with the same items.',
    quantity: 'Quantity',
    remaining_qty: '{count} left',
    retry: 'Retry',
    retry_submit: 'Resend',
    save: 'Save',
    search: 'Search',
    search_food: 'Search food',
    select: 'Select',
    select_max: 'Select up to {count}',
    select_one: 'Select 1',
    served_all: 'Served',
    served_qty: 'Served {served}/{total}',
    sent_order: 'Order sent',
    sent_order_detail: 'The order has been sent to the cashier.',
    session_failed_body: 'Refresh this page or contact staff.',
    session_failed_title: 'Could not open session',
    sold_out: 'Sold out',
    stock_limit: 'Stock limit',
    stock_limit_detail: '{name} has {count} left',
    submit_order: 'Send order',
    table: 'Table',
    table_order: 'On table',
    unknown_device: 'Unknown device',
    updated_latest: 'Updated',
    waiting_kitchen: 'Waiting for kitchen',
  },
  th: {
    add_to_cart: 'ใส่ตะกร้า',
    all_items: 'ทั้งหมด',
    back_to_edit: 'กลับไปแก้ไข',
    basket: 'ตะกร้า',
    call_staff: 'เรียกพนักงาน',
    call_staff_failed: 'เรียกพนักงานไม่สำเร็จ',
    call_staff_success: 'เรียกพนักงานแล้ว',
    cart: 'ตะกร้า',
    cart_items: 'รายการในตะกร้า',
    check_status: 'ตรวจสอบสถานะ',
    close: 'ปิด',
    closed_order: 'ปิดสั่ง',
    confirm_submit: 'ยืนยันส่งออเดอร์',
    confirm_submit_body: 'ตรวจสอบรายการเรียบร้อยแล้วส่งเข้าแคชเชียร์และครัว',
    device: 'เครื่อง',
    edit: 'แก้ไข',
    edited_cart: 'แก้ไขรายการแล้ว',
    error_default: 'เกิดข้อผิดพลาด',
    drink_items: 'เครื่องดื่ม',
    food_items: 'อาหาร',
    item_count: 'รายการ',
    items: 'รายการ',
    language: 'ภาษา',
    loading_menu: 'กำลังโหลดเมนู',
    loading_products: 'กำลังโหลดรายการ',
    max_selected: 'เลือกครบแล้ว',
    menu: 'เมนู',
    missing_options: 'เลือกตัวเลือกไม่ครบ',
    no_cart_items: 'ยังไม่มีรายการในตะกร้า',
    no_orders: 'ยังไม่มีรายการที่ส่งแล้ว',
    no_products: 'ไม่พบสินค้า',
    no_qr_body: 'กรุณาสแกน QR จากใบเปิดโต๊ะอีกครั้ง',
    no_qr_title: 'ไม่พบ QR สำหรับสั่งอาหาร',
    not_found_order: 'ยังไม่พบออเดอร์นี้',
    note: 'หมายเหตุ',
    open_order: 'สั่งได้',
    order_failed: 'ยังส่งออเดอร์ไม่สำเร็จ',
    order_pending: 'มีออเดอร์ค้างส่ง',
    order_pending_detail: 'กรุณาตรวจสอบหรือส่งรายการค้างก่อนแก้ตะกร้า',
    ordered: 'ส่งออเดอร์แล้ว',
    
    ordered_total: 'ยอดรวม',
    orders: 'รายการที่สั่ง',
    pending_attempts: 'ครั้ง',
    pending_order: 'มีออเดอร์ที่ยังรอยืนยัน',
    pending_retry_hint: 'ลองส่งซ้ำด้วยรายการเดิมได้',
    quantity: 'จำนวน',
    retry: 'ลองใหม่',
    retry_submit: 'ลองส่งอีกครั้ง',
    save: 'บันทึก',
    search: 'ค้นหา',
    search_food: 'ค้นหาอาหาร',
    select: 'เลือก',
    select_max: 'เลือกได้ {count}',
    select_one: 'เลือก 1',
    sent_order: 'ส่งออเดอร์แล้ว',
    sent_order_detail: 'รายการถูกส่งเข้าแคชเชียร์แล้ว',
    session_failed_body: 'ลองรีเฟรช หรือแจ้งพนักงาน',
    session_failed_title: 'เปิด session ไม่สำเร็จ',
    submit_order: 'ส่งออเดอร์',
    table: 'โต๊ะ',
    table_order: 'รายการในโต๊ะ',
    unknown_device: 'ไม่ทราบเครื่อง',
    updated_latest: 'อัปเดตล่าสุด',
  },
};

const thOverrides: Partial<Record<TranslationKey, string>> = {
  canceled_all: '\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14 {count}',
  canceled_items: '\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01',
  canceled_qty: '\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01 {count}',
  kitchen_done: '\u0e04\u0e23\u0e31\u0e27\u0e17\u0e33\u0e40\u0e2a\u0e23\u0e47\u0e08',
  remaining_qty: '\u0e40\u0e2b\u0e25\u0e37\u0e2d {count}',
  served_all: '\u0e40\u0e2a\u0e34\u0e23\u0e4c\u0e1f\u0e41\u0e25\u0e49\u0e27',
  served_qty: '\u0e40\u0e2a\u0e34\u0e23\u0e4c\u0e1f {served}/{total}',
  sold_out: '\u0e2b\u0e21\u0e14',
  stock_limit: '\u0e2a\u0e15\u0e47\u0e2d\u0e01\u0e44\u0e21\u0e48\u0e1e\u0e2d',
  stock_limit_detail: '{name} \u0e40\u0e2b\u0e25\u0e37\u0e2d {count}',
  waiting_kitchen: '\u0e23\u0e2d\u0e04\u0e23\u0e31\u0e27',
};

export const currentLanguage = ref<LanguageCode>(readStoredLanguage());

export const currentIntlLocale = computed(() => localeByLanguage[currentLanguage.value]);

export function setLanguage(language: string) {
  currentLanguage.value = normalizeLanguage(language);
  try {
    window.localStorage.setItem(storageKey, currentLanguage.value);
  } catch {
    // Keep language switching usable even when storage is blocked.
  }
}

export function languageCodeCandidates(language = currentLanguage.value): string[] {
  const normalized = normalizeLanguage(language);
  const aliasMap: Record<LanguageCode, string[]> = {
    en: ['en', 'en-us'],
    th: ['th', 'th-th'],
    lo: ['lo', 'lo-la', 'la'],
    'zh-cn': ['zh-cn', 'zh', 'cn', 'ch'],
    ja: ['ja', 'jp', 'ja-jp'],
    ko: ['ko', 'kr', 'ko-kr'],
  };
  return [...aliasMap[normalized], 'th', 'en'];
}

export function t(key: TranslationKey, values: Record<string, string | number> = {}): string {
  const dictionaryKey = currentLanguage.value === 'th' ? 'th' : 'en';
  let text = (dictionaryKey === 'th' ? thOverrides[key] : undefined) ?? dictionaries[dictionaryKey][key] ?? dictionaries.en[key] ?? key;
  for (const [name, value] of Object.entries(values)) {
    text = text.replaceAll(`{${name}}`, String(value));
  }
  return text;
}

function readStoredLanguage(): LanguageCode {
  try {
    return normalizeLanguage(window.localStorage.getItem(storageKey) ?? '');
  } catch {
    return 'th';
  }
}

function normalizeLanguage(language: string): LanguageCode {
  const value = language.trim().toLowerCase();
  if (value === 'en' || value === 'en-us') return 'en';
  if (value === 'lo' || value === 'lo-la' || value === 'la') return 'lo';
  if (value === 'zh' || value === 'zh-cn' || value === 'cn' || value === 'ch') return 'zh-cn';
  if (value === 'ja' || value === 'ja-jp' || value === 'jp') return 'ja';
  if (value === 'ko' || value === 'ko-kr' || value === 'kr') return 'ko';
  return 'th';
}
