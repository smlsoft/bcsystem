<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from "vue";
import Badge from "primevue/badge";
import Button from "primevue/button";
import Dialog from "primevue/dialog";
import InputText from "primevue/inputtext";
import ProgressSpinner from "primevue/progressspinner";
import Tab from "primevue/tab";
import TabList from "primevue/tablist";
import TabPanel from "primevue/tabpanel";
import TabPanels from "primevue/tabpanels";
import Tabs from "primevue/tabs";
import Tag from "primevue/tag";
import Textarea from "primevue/textarea";
import Toast from "primevue/toast";
import { useToast } from "primevue/usetoast";
import { callStaff, getProduct, getSession, listCategories, listProducts, listSessionOrders, submitOrder, validateCart } from "./services/orderOnlineApi";
import { currentIntlLocale, currentLanguage, languageOptions, setLanguage, t } from "./i18n";
import type { CartLine, OrderBatch, OrderBatchItem, PendingSubmit, ProductBarcode, ProductCategory, ProductOption, SubmitOrderItem, TableSession } from "./types";
import { cloneOptions, imageOf, lineAmount, money, nameOf, parseOptions, priceOf, productName, selectedOptionText, unitName } from "./utils/menu";
import { readJson, removeJson, writeJson } from "./utils/storage";

const toast = useToast();
const token = ref(resolveToken());
const activeTab = ref("menu");
const loading = ref(true);
const loadingProducts = ref(false);
const submitting = ref(false);
const callingStaff = ref(false);
const session = ref<TableSession | null>(null);
const categories = ref<ProductCategory[]>([]);
const products = ref<ProductBarcode[]>([]);
const orders = ref<OrderBatch[]>([]);
const cart = ref<CartLine[]>([]);
const search = ref("");
const selectedCategory = ref("");
const productDialog = ref(false);
const confirmDialog = ref(false);
const languageMenuOpen = ref(false);
const selectedProduct = ref<ProductBarcode | null>(null);
const editingLineId = ref("");
const draftQty = ref(1);
const draftRemark = ref("");
const draftOptions = ref<ProductOption[]>([]);
const imagePreviewDialog = ref(false);
const optionErrors = ref<Record<string, string>>({});
const pendingSubmit = ref<PendingSubmit | null>(null);
const lastOrderRefresh = ref("");
const orderLoadError = ref("");
const customerDeviceId = ref(resolveCustomerDeviceId());
let orderPoll: number | undefined;

const cartStorageKey = computed(() => (token.value ? `bcorderonline:${token.value}:${customerDeviceId.value}:cart` : ""));
const pendingSubmitStorageKey = computed(() => (token.value ? `bcorderonline:${token.value}:${customerDeviceId.value}:pending-submit` : ""));
const selectedLanguage = computed({
  get: () => currentLanguage.value,
  set: (value: string) => chooseLanguage(value),
});
const selectedLanguageOption = computed(() => languageOptions.find((language) => language.code === currentLanguage.value) ?? languageOptions.find((language) => language.code === "th")!);
const canOrder = computed(() => Boolean(session.value?.canorder));
const tableNumber = computed(() => session.value?.tablenumber || "-");
const cartQty = computed(() => cart.value.reduce((sum, line) => sum + line.qty, 0));
const cartTotal = computed(() => cart.value.reduce((sum, line) => sum + lineAmount(line), 0));
const orderedTotal = computed(() => orders.value.reduce((sum, order) => sum + Number(order.totalamount ?? 0), 0));
const productFoodTypeByBarcode = computed(() => {
  const map = new Map<string, number>();
  for (const product of products.value) {
    const foodType = readFoodType(product);
    if (product.barcode && foodType !== undefined) {
      map.set(product.barcode, foodType);
    }
  }
  return map;
});
const orderedFoodQty = computed(() => orders.value.reduce((sum, order) => sum + orderFoodQty(order), 0));
const orderedDrinkQty = computed(() => orders.value.reduce((sum, order) => sum + orderDrinkQty(order), 0));
const orderedCanceledQty = computed(() => orders.value.reduce((sum, order) => sum + orderCanceledQty(order), 0));
const selectedProductTotal = computed(() => {
  if (!selectedProduct.value) return 0;
  const line: CartLine = {
    lineId: "draft",
    product: selectedProduct.value,
    qty: draftQty.value,
    remark: draftRemark.value,
    options: draftOptions.value,
  };
  return lineAmount(line);
});
const selectedProductImage = computed(() => (selectedProduct.value ? imageOf(selectedProduct.value) : ""));
const pendingUpdatedText = computed(() => {
  if (!pendingSubmit.value?.updatedAt) return "";
  return new Date(pendingSubmit.value.updatedAt).toLocaleTimeString(currentIntlLocale.value, {
    hour: "2-digit",
    minute: "2-digit",
  });
});
const lastOrderRefreshText = computed(() => {
  if (!lastOrderRefresh.value) return "";
  return new Date(lastOrderRefresh.value).toLocaleTimeString(currentIntlLocale.value, {
    hour: "2-digit",
    minute: "2-digit",
  });
});

watch(
  cart,
  () => {
    if (!cartStorageKey.value) return;
    if (cart.value.length) writeJson(cartStorageKey.value, cart.value);
    else removeJson(cartStorageKey.value);
  },
  { deep: true },
);

watch(
  pendingSubmit,
  () => {
    if (!pendingSubmitStorageKey.value) return;
    if (pendingSubmit.value) writeJson(pendingSubmitStorageKey.value, pendingSubmit.value);
    else removeJson(pendingSubmitStorageKey.value);
  },
  { deep: true },
);

watch(productDialog, (visible) => {
  if (!visible) imagePreviewDialog.value = false;
});

onMounted(async () => {
  await initialize();
});

onUnmounted(() => {
  if (orderPoll) window.clearInterval(orderPoll);
});

async function initialize() {
  if (!token.value) {
    loading.value = false;
    return;
  }
  try {
    loading.value = true;
    session.value = await getSession(token.value);
    restoreLocalState();
    const [categoryList] = await Promise.all([listCategories(token.value), loadProducts()]);
    categories.value = categoryList.slice().sort((a, b) => {
      if (isAllProductsCategory(a)) return -1;
      if (isAllProductsCategory(b)) return 1;
      const aOrder = a.xsorts?.find((s) => s.code === "X")?.xorder ?? 999999;
      const bOrder = b.xsorts?.find((s) => s.code === "X")?.xorder ?? 999999;
      return aOrder - bOrder;
    });
    const defaultCategory = categories.value.find((c: ProductCategory) => c.guidfixed === "00000000000000000");
    if (defaultCategory) {
      selectedCategory.value = categoryKey(defaultCategory);
    }
    await loadOrders();
    orderPoll = window.setInterval(() => {
      void pollSessionState();
    }, 15000);
  } catch (error) {
    toast.add({
      severity: "error",
      summary: t("session_failed_title"),
      detail: errorMessage(error),
      life: 5000,
    });
  } finally {
    loading.value = false;
  }
}

function restoreLocalState() {
  if (!cartStorageKey.value || !pendingSubmitStorageKey.value) return;
  cart.value = readJson<CartLine[]>(cartStorageKey.value, []);
  pendingSubmit.value = readJson<PendingSubmit | null>(pendingSubmitStorageKey.value, null);
  if (pendingSubmit.value && !cart.value.length) {
    cart.value = pendingSubmit.value.cartSnapshot;
  }
  if (pendingSubmit.value) {
    activeTab.value = "cart";
  }
}

async function loadProducts(options: { silent?: boolean } = {}) {
  if (!token.value) return;
  const silent = options.silent === true;
  try {
    if (!silent) loadingProducts.value = true;
    const loadedProducts = await listProducts(token.value, {
      q: search.value.trim(),
      categoryCode: selectedCategoryFallbackCode(),
      barcodes: selectedCategoryBarcodes(),
      limit: 500,
    });
    products.value = sortProductsForMenu(loadedProducts);
    syncCartProducts(products.value);
  } catch (error) {
    if (!silent) {
      toast.add({
        severity: "warn",
        summary: t("loading_products"),
        detail: errorMessage(error),
        life: 3500,
      });
    }
  } finally {
    if (!silent) loadingProducts.value = false;
  }
}

function clearSearch() {
  if (!search.value) return;
  search.value = "";
  void loadProducts();
}

async function pollSessionState() {
  await loadOrders();
  await loadProducts({ silent: true });
}

async function loadOrders() {
  if (!token.value) return;
  try {
    orders.value = await listSessionOrders(token.value);
    orderLoadError.value = "";
    lastOrderRefresh.value = new Date().toISOString();
    reconcilePendingSubmit();
  } catch (error) {
    orderLoadError.value = errorMessage(error);
  }
}

function reconcilePendingSubmit() {
  if (!pendingSubmit.value) return;
  const found = orders.value.find((order) => order.idempotencykey === pendingSubmit.value?.idempotencyKey);
  if (!found) return;
  clearPendingSubmit();
  cart.value = [];
  confirmDialog.value = false;
}

async function openProduct(product: ProductBarcode, line?: CartLine) {
  if (!line && productIsSoldOut(product)) {
    toast.add({
      severity: "info",
      summary: t("sold_out"),
      detail: productName(product),
      life: 2200,
    });
    return;
  }
  selectedProduct.value = product;
  editingLineId.value = line?.lineId ?? "";
  draftQty.value = clampProductQty(product, line?.qty ?? 1, line?.lineId);
  draftRemark.value = line?.remark ?? "";
  draftOptions.value = line?.options ? cloneOptions(line.options) : parseOptions(product);
  optionErrors.value = {};

  if (!draftOptions.value.length) {
    try {
      const fresh = await getProduct(token.value, product.barcode);
      selectedProduct.value = { ...product, ...fresh };
      draftOptions.value = parseOptions(selectedProduct.value);
    } catch {
      draftOptions.value = [];
    }
  }

  productDialog.value = true;
}

function changeDraftQty(delta: number) {
  if (!selectedProduct.value) return;
  const nextQty = clampProductQty(selectedProduct.value, draftQty.value + delta, editingLineId.value);
  if (nextQty < draftQty.value + delta) {
    showStockLimitToast(selectedProduct.value, nextQty);
  }
  draftQty.value = Math.max(1, nextQty);
}

function chooseCategory(category: ProductCategory | null) {
  const nextKey = category ? categoryKey(category) : "";
  selectedCategory.value = selectedCategory.value === nextKey ? "" : nextKey;
  void loadProducts();
}

function toggleChoice(option: ProductOption, choiceIndex: number) {
  const minSelect = optionMinSelect(option);
  const maxSelect = optionMaxSelect(option);
  const choice = option.choices[choiceIndex];
  if (!choice) return;

  if (isSingleChoiceOption(option)) {
    if (choice.selected && minSelect === 0) {
      choice.selected = false;
      validateDraftOptions();
      return;
    }
    option.choices.forEach((item) => {
      item.selected = false;
    });
    choice.selected = true;
    validateDraftOptions();
    return;
  }

  if (choice.selected) {
    choice.selected = false;
    validateDraftOptions();
    return;
  }

  const selectedCount = option.choices.filter((item) => item.selected).length;
  if (selectedCount < maxSelect) {
    choice.selected = true;
    validateDraftOptions();
  } else {
    toast.add({
      severity: "info",
      summary: t("max_selected"),
      detail: t("select_max", { count: maxSelect }),
      life: 2200,
    });
  }
}

function addDraftToCart() {
  if (!selectedProduct.value || draftQty.value <= 0) return;
  if (pendingSubmit.value) {
    toast.add({
      severity: "warn",
      summary: t("order_pending"),
      detail: t("order_pending_detail"),
      life: 3000,
    });
    return;
  }
  if (!validateDraftOptions()) return;

  const allowedQty = clampProductQty(selectedProduct.value, draftQty.value, editingLineId.value);
  if (allowedQty < 1) {
    showStockLimitToast(selectedProduct.value, allowedQty);
    return;
  }
  if (allowedQty < draftQty.value) {
    draftQty.value = allowedQty;
    showStockLimitToast(selectedProduct.value, allowedQty);
    return;
  }

  const line: CartLine = {
    lineId: editingLineId.value || newClientId("line"),
    product: selectedProduct.value,
    qty: allowedQty,
    remark: draftRemark.value.trim(),
    options: cloneOptions(draftOptions.value),
  };

  const existingIndex = cart.value.findIndex((item) => item.lineId === line.lineId);
  if (existingIndex >= 0) {
    cart.value.splice(existingIndex, 1, line);
  } else {
    cart.value.push(line);
  }

  productDialog.value = false;
  if (!editingLineId.value) activeTab.value = "menu";
  toast.add({
    severity: "success",
    summary: editingLineId.value ? t("edited_cart") : t("add_to_cart"),
    detail: productName(line.product),
    life: 1800,
  });
}

function optionSignature(options: ProductOption[]): string {
  return JSON.stringify(
    options.map((option) => ({
      guid: option.guid,
      selected: (option.choices ?? [])
        .filter((choice) => choice.selected)
        .map((choice) => choice.guid)
        .sort(),
    })),
  );
}

function productCartQty(product: ProductBarcode): number {
  return cart.value.filter((line) => line.product.barcode === product.barcode).reduce((sum, line) => sum + line.qty, 0);
}

function productCartQtyExcept(product: ProductBarcode, exceptLineId = ""): number {
  return cart.value.filter((line) => line.lineId !== exceptLineId && line.product.barcode === product.barcode).reduce((sum, line) => sum + line.qty, 0);
}

function quickLineIndex(product: ProductBarcode, options: ProductOption[]): number {
  const signature = optionSignature(options);
  return cart.value.findIndex((line) => line.product.barcode === product.barcode && line.remark === "" && optionSignature(line.options) === signature);
}

function quickAddProduct(product: ProductBarcode) {
  if (!canOrder.value || pendingSubmit.value || productIsSoldOut(product)) return;
  const remaining = productRemainingQty(product);
  if (remaining !== null && remaining < 1) {
    showStockLimitToast(product, 0);
    return;
  }
  const options = parseOptions(product);
  const existingIndex = quickLineIndex(product, options);
  if (existingIndex >= 0) {
    const line = cart.value[existingIndex];
    if (!canIncreaseLineQty(line)) {
      showStockLimitToast(product, line.qty);
      return;
    }
    cart.value[existingIndex].qty += 1;
    return;
  }
  cart.value.push({
    lineId: newClientId("quick-line"),
    product,
    qty: 1,
    remark: "",
    options,
  });
}

function quickRemoveProduct(product: ProductBarcode) {
  if (pendingSubmit.value) return;
  const index = cart.value
    .map((line, lineIndex) => ({ line, lineIndex }))
    .reverse()
    .find((item) => item.line.product.barcode === product.barcode)?.lineIndex;
  if (index === undefined) return;
  if (cart.value[index].qty > 1) {
    cart.value[index].qty -= 1;
    return;
  }
  cart.value.splice(index, 1);
}

function hasProductOptions(product: ProductBarcode): boolean {
  return parseOptions(product).length > 0;
}

function boolish(value: boolean | number | undefined): boolean {
  return value === true || value === 1;
}

function productStockLimit(product: ProductBarcode): number | null {
  if (!boolish(product.orderautostock)) return null;
  const qtyBalance = Number(product.qtybalance ?? 0);
  if (!Number.isFinite(qtyBalance)) return 0;
  return Math.max(0, Math.floor(qtyBalance));
}

function productRemainingQty(product: ProductBarcode, exceptLineId = ""): number | null {
  const limit = productStockLimit(product);
  if (limit === null) return null;
  return Math.max(0, limit - productCartQtyExcept(product, exceptLineId));
}

function clampProductQty(product: ProductBarcode, qty: number, exceptLineId = ""): number {
  const nextQty = Math.max(1, Math.floor(qty || 1));
  const remaining = productRemainingQty(product, exceptLineId);
  return remaining === null ? nextQty : Math.min(nextQty, remaining);
}

function maxQtyForLine(line: CartLine): number | null {
  return productRemainingQty(line.product, line.lineId);
}

function clampLineQty(line: CartLine, qty: number): number {
  const nextQty = Math.max(1, Math.floor(qty || 1));
  const maxQty = maxQtyForLine(line);
  return maxQty === null ? nextQty : Math.min(nextQty, maxQty);
}

function canIncreaseLineQty(line: CartLine): boolean {
  const maxQty = maxQtyForLine(line);
  return maxQty === null || line.qty < maxQty;
}

function canIncreaseDraftQty(): boolean {
  if (!selectedProduct.value) return false;
  const remaining = productRemainingQty(selectedProduct.value, editingLineId.value);
  return remaining === null || draftQty.value < remaining;
}

function productStockText(product: ProductBarcode, exceptLineId = ""): string {
  if (productStockLimit(product) === null) return "";
  const remaining = productRemainingQty(product, exceptLineId) ?? 0;
  return t("remaining_qty", { count: qtyText(remaining) });
}

function showStockLimitToast(product: ProductBarcode, maxQty: number) {
  toast.add({
    severity: "warn",
    summary: t("stock_limit"),
    detail: t("stock_limit_detail", { name: productName(product), count: qtyText(Math.max(0, maxQty)) }),
    life: 2600,
  });
}

function productIsSoldOut(product: ProductBarcode): boolean {
  if (boolish(product.orderdisable)) return true;
  if (boolish(product.orderautostock)) return Number(product.qtybalance ?? 0) < 1;
  if (product.issoldout !== undefined) return product.issoldout;
  if (product.isavailablefororder === false) return true;
  if (Number(product.orderstatus ?? 0) !== 0) return true;
  return false;
}

function productCanOrder(product: ProductBarcode): boolean {
  const remaining = productRemainingQty(product);
  return canOrder.value && !pendingSubmit.value && !productIsSoldOut(product) && (remaining === null || remaining > 0);
}

function sortProductsForMenu(productList: ProductBarcode[]): ProductBarcode[] {
  return productList.slice().sort((a, b) => Number(productIsSoldOut(a)) - Number(productIsSoldOut(b)));
}

function syncCartProducts(productList: ProductBarcode[]) {
  if (!cart.value.length || !productList.length) return;
  const latestByBarcode = new Map(productList.map((product) => [product.barcode, product]));
  for (const line of cart.value) {
    const latest = latestByBarcode.get(line.product.barcode);
    if (latest) line.product = { ...line.product, ...latest };
  }
  cart.value = cart.value.filter((line) => {
    const nextQty = clampLineQty(line, line.qty);
    if (nextQty < 1) return false;
    line.qty = nextQty;
    return true;
  });
}

function updateLineQty(line: CartLine, qty: number) {
  if (pendingSubmit.value) return;
  const nextQty = clampLineQty(line, qty);
  if (nextQty < qty) {
    showStockLimitToast(line.product, nextQty);
  }
  line.qty = Math.max(1, nextQty);
}

function removeLine(lineId: string) {
  if (pendingSubmit.value) return;
  cart.value = cart.value.filter((line) => line.lineId !== lineId);
}

function buildItems(): SubmitOrderItem[] {
  return cart.value.map((line) => ({
    barcode: line.product.barcode,
    qty: line.qty,
    optionselected: line.options,
    remark: line.remark,
  }));
}

function cartSnapshot(): CartLine[] {
  return JSON.parse(JSON.stringify(cart.value)) as CartLine[];
}

function validateCartStock(): boolean {
  for (const line of cart.value) {
    const maxQty = maxQtyForLine(line);
    if (maxQty !== null && line.qty > maxQty) {
      showStockLimitToast(line.product, maxQty);
      return false;
    }
    if (productIsSoldOut(line.product)) {
      showStockLimitToast(line.product, 0);
      return false;
    }
  }
  return true;
}

async function confirmSubmit() {
  if (!token.value || !cart.value.length) return;
  if (pendingSubmit.value) {
    await retryPendingSubmit();
    return;
  }
  if (!validateCartStock()) return;
  const idempotencyKey = newClientId("order");
  pendingSubmit.value = {
    idempotencyKey,
    customerDeviceId: customerDeviceId.value,
    items: buildItems(),
    cartSnapshot: cartSnapshot(),
    attempts: 0,
    lastError: "",
    updatedAt: new Date().toISOString(),
  };
  await sendPendingSubmit();
}

async function retryPendingSubmit() {
  if (!pendingSubmit.value) return;
  cart.value = pendingSubmit.value.cartSnapshot;
  await sendPendingSubmit();
}

async function checkPendingStatus() {
  await loadOrders();
  if (pendingSubmit.value) {
    toast.add({
      severity: "info",
      summary: t("not_found_order"),
      detail: t("pending_retry_hint"),
      life: 3000,
    });
  }
}

async function requestStaff() {
  if (!token.value || callingStaff.value) return;
  try {
    callingStaff.value = true;
    await callStaff(token.value, customerDeviceId.value);
    toast.add({
      severity: "success",
      summary: t("call_staff_success"),
      detail: `${t("table")} ${tableNumber.value}`,
      life: 2500,
    });
  } catch (error) {
    toast.add({
      severity: "warn",
      summary: t("call_staff_failed"),
      detail: errorMessage(error),
      life: 4000,
    });
  } finally {
    callingStaff.value = false;
  }
}

async function sendPendingSubmit() {
  if (!token.value || !pendingSubmit.value) return;
  const submitDeviceId = pendingSubmit.value.customerDeviceId || customerDeviceId.value;
  try {
    submitting.value = true;
    pendingSubmit.value = {
      ...pendingSubmit.value,
      attempts: pendingSubmit.value.attempts + 1,
      lastError: "",
      updatedAt: new Date().toISOString(),
    };
    try {
      await validateCart(token.value, pendingSubmit.value.idempotencyKey, submitDeviceId, pendingSubmit.value.items);
    } catch (error) {
      toast.add({
        severity: "warn",
        summary: t("order_failed"),
        detail: errorMessage(error),
        life: 5000,
      });
      clearPendingSubmit();
      await loadProducts({ silent: true });
      return;
    }
    await submitOrder(token.value, pendingSubmit.value.idempotencyKey, submitDeviceId, pendingSubmit.value.items);
    cart.value = [];
    clearPendingSubmit();
    confirmDialog.value = false;
    activeTab.value = "orders";
    await pollSessionState();
    toast.add({
      severity: "success",
      summary: t("sent_order"),
      detail: t("sent_order_detail"),
      life: 3500,
    });
  } catch (error) {
    toast.add({
      severity: "warn",
      summary: t("order_failed"),
      detail: errorMessage(error),
      life: 5000,
    });
    pendingSubmit.value = {
      ...pendingSubmit.value,
      lastError: errorMessage(error),
      updatedAt: new Date().toISOString(),
    };
  } finally {
    submitting.value = false;
  }
}

function clearPendingSubmit() {
  pendingSubmit.value = null;
}

function validateDraftOptions(): boolean {
  const errors: Record<string, string> = {};
  for (const option of draftOptions.value) {
    const minSelect = optionMinSelect(option);
    const maxSelect = optionMaxSelect(option);
    const selectedCount = option.choices.filter((choice) => choice.selected).length;
    if (minSelect > 0 && selectedCount < minSelect) {
      errors[option.guid] = t("select_max", { count: minSelect });
    } else if (selectedCount > maxSelect) {
      errors[option.guid] = t("select_max", { count: maxSelect });
    }
  }
  optionErrors.value = errors;
  if (Object.keys(errors).length) {
    toast.add({
      severity: "warn",
      summary: t("missing_options"),
      detail: Object.values(errors)[0],
      life: 3000,
    });
    return false;
  }
  return true;
}

function optionMinSelect(option: ProductOption): number {
  // Staff stores minselect in the option model, but it does not use it to
  // force a choice. Keep orderonline behavior aligned with staff.
  void option;
  return 0;
}

function optionMaxSelect(option: ProductOption): number {
  const raw = Number(option.maxselect ?? 0);
  if (Number.isFinite(raw) && raw > 0) return raw;
  if (option.choicetype === 1) return 1;
  return Math.max(option.choices.length, 1);
}

function isSingleChoiceOption(option: ProductOption): boolean {
  return option.choicetype === 1 || optionMaxSelect(option) === 1;
}

function choiceIcon(option: ProductOption, selected?: boolean): string {
  if (isSingleChoiceOption(option)) {
    return selected ? "pi pi-check-circle" : "pi pi-circle";
  }
  return selected ? "pi pi-check-square" : "pi pi-stop";
}

function optionRuleText(option: ProductOption): string {
  const staffMaxSelect = optionMaxSelect(option);
  return staffMaxSelect === 1 ? t("select_one") : t("select_max", { count: staffMaxSelect });
}

function categoryKey(category: ProductCategory): string {
  return category.guidfixed || category.code || categoryName(category);
}

function isAllProductsCategory(category: ProductCategory): boolean {
  return category.guidfixed === "00000000000000000";
}

function categoryName(category: ProductCategory): string {
  return nameOf(category.names) || category.name || category.code || "";
}

function categoryBarcodes(category: ProductCategory): string[] {
  return (category.codelist ?? []).map((item) => item.barcode?.trim() ?? "").filter((barcode, index, all) => barcode.length > 0 && all.indexOf(barcode) === index);
}

function selectedCategoryItem(): ProductCategory | undefined {
  return categories.value.find((category) => categoryKey(category) === selectedCategory.value);
}

function selectedCategoryBarcodes(): string[] | undefined {
  const category = selectedCategoryItem();
  if (!category) return undefined;
  const barcodes = categoryBarcodes(category);
  return barcodes.length ? barcodes : undefined;
}

function selectedCategoryFallbackCode(): string | undefined {
  const category = selectedCategoryItem();
  if (!category || categoryBarcodes(category).length) return undefined;
  return category.code || undefined;
}

function readFoodType(value?: { foodtype?: number; food_type?: number }): number | undefined {
  const raw = value?.foodtype ?? value?.food_type;
  return raw === undefined || raw === null ? undefined : Number(raw);
}

function orderItemFoodType(item: OrderBatchItem): number {
  const explicitFoodType = readFoodType(item);
  if (explicitFoodType !== undefined && Number.isFinite(explicitFoodType)) {
    return explicitFoodType;
  }
  return productFoodTypeByBarcode.value.get(item.barcode) ?? 0;
}

function isDrinkFoodType(foodType: number): boolean {
  return foodType === 1 || foodType === 2;
}

function orderFoodQty(order: OrderBatch): number {
  return (order.items ?? []).reduce((sum, item) => {
    return isDrinkFoodType(orderItemFoodType(item)) ? sum : sum + Number(item.qty || 0);
  }, 0);
}

function orderDrinkQty(order: OrderBatch): number {
  return (order.items ?? []).reduce((sum, item) => {
    return isDrinkFoodType(orderItemFoodType(item)) ? sum + Number(item.qty || 0) : sum;
  }, 0);
}

function itemCancelQty(item: OrderBatchItem): number {
  return Number(item.cancelqty ?? 0);
}

function itemIsCancelled(item: OrderBatchItem): boolean {
  return Boolean(item.iscancelled) || (Number(item.qty || 0) <= 0 && itemCancelQty(item) > 0);
}

function itemOrderQty(item: OrderBatchItem): number {
  const orderQty = Number(item.orderqty ?? 0);
  if (orderQty > 0) return orderQty;
  return Number(item.qty || 0) + itemCancelQty(item);
}

function itemServedQty(item: OrderBatchItem): number {
  return Number(item.servedqty ?? 0);
}

function itemProgressText(item: OrderBatchItem): string {
  if (itemIsCancelled(item)) return "";
  const servedQty = itemServedQty(item);
  const orderQty = itemOrderQty(item);
  if (servedQty > 0) {
    if (Boolean(item.servedsuccess) || servedQty >= orderQty) {
      return t("served_all");
    }
    return t("served_qty", { served: qtyText(servedQty), total: qtyText(orderQty) });
  }
  if (Boolean(item.kdssuccess)) {
    return t("kitchen_done");
  }
  return t("waiting_kitchen");
}

function orderCanceledQty(order: OrderBatch): number {
  return (order.items ?? []).reduce((sum, item) => sum + itemCancelQty(item), 0);
}

function qtyText(qty: number): string {
  return new Intl.NumberFormat(currentIntlLocale.value, {
    maximumFractionDigits: 2,
  }).format(qty);
}

function resolveToken(): string {
  const url = new URL(window.location.href);
  const q = url.searchParams.get("q") || url.searchParams.get("token") || url.searchParams.get("t");
  if (q) return q.trim();
  const parts = url.pathname.split("/").filter(Boolean);
  const sessionIndex = parts.findIndex((part) => part === "session");
  if (sessionIndex >= 0 && parts[sessionIndex + 1]) return parts[sessionIndex + 1];
  return parts.length === 1 ? parts[0] : "";
}

function resolveCustomerDeviceId(): string {
  const storageKey = "bcorderonline:customer-device-id";
  try {
    const existing = window.localStorage.getItem(storageKey)?.trim();
    if (existing) return existing;
  } catch {
    // Keep ordering usable even when storage is blocked.
  }
  const nextId = newClientId("c");
  try {
    window.localStorage.setItem(storageKey, nextId);
  } catch {
    // The runtime ID still separates the cart for this tab session.
  }
  return nextId;
}

function newClientId(prefix = "id"): string {
  if (typeof globalThis.crypto?.randomUUID === "function") {
    return globalThis.crypto.randomUUID().replace(/-/g, "").slice(0, 8).toUpperCase();
  }
  const randomPart = Math.random().toString(36).slice(2, 12);
  const timePart = Date.now().toString(36);
  return `${prefix}${timePart}${randomPart}`.slice(0, 10).toUpperCase();
}

function shortDeviceId(deviceId?: string): string {
  return deviceId ? deviceId : "-";
}

function chooseLanguage(language: string) {
  setLanguage(language);
  languageMenuOpen.value = false;
}

function flagSrc(languageCode: string): string {
  return `/flags/${languageCode}.png`;
}

function timeText(value?: string): string {
  if (!value) return "-";
  return new Date(value).toLocaleTimeString(currentIntlLocale.value, {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function orderDeviceText(deviceId?: string): string {
  if (!deviceId) return t("unknown_device");
  if (deviceId === customerDeviceId.value) return `${t("device")}: ${shortDeviceId(deviceId)}`;
  return `${t("device")} ${shortDeviceId(deviceId)}`;
}

function orderStatusText(status: string): string {
  switch (status) {
    case "submitted":
      return t("order_pending");
    case "claimed":
      return t("ordered");
    case "kitchen_sent":
      return t("sent_order");
    case "table_status":
      return t("table_order");
    case "failed":
      return t("order_failed");
    default:
      return status || "-";
  }
}

function orderSeverity(status: string) {
  if (status === "kitchen_sent") return "success";
  if (status === "table_status") return "info";
  if (status === "failed" || status === "rejected") return "danger";
  if (status === "claimed") return "info";
  return "warning";
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : t("error_default");
}
</script>

<template>
  <Toast position="top-center" />
  <main class="order-shell">
    <section v-if="loading" class="center-state">
      <ProgressSpinner />
      <p>{{ t("loading_menu") }}</p>
    </section>

    <section v-else-if="!token" class="center-state">
      <i class="pi pi-qrcode state-icon"></i>
      <h1>{{ t("no_qr_title") }}</h1>
      <p>{{ t("no_qr_body") }}</p>
    </section>

    <section v-else-if="!session" class="center-state">
      <i class="pi pi-wifi state-icon"></i>
      <h1>{{ t("session_failed_title") }}</h1>
      <p>{{ t("session_failed_body") }}</p>
      <Button :label="t('retry')" icon="pi pi-refresh" @click="initialize" />
    </section>

    <template v-else>
      <header class="top-bar">
        <div>
          <span class="eyebrow">{{ t("table") }}</span>
          <h1>{{ tableNumber }}</h1>
          <small class="device-label">{{ t("device") }} {{ shortDeviceId(customerDeviceId) }}</small>
        </div>
        <div class="top-actions">
          <div class="language-select">
            <button class="language-trigger" type="button" :aria-label="t('language')" @click="languageMenuOpen = !languageMenuOpen">
              <img :src="flagSrc(selectedLanguageOption.code)" :alt="selectedLanguageOption.label" />
              <i class="pi pi-chevron-down"></i>
            </button>
            <div v-if="languageMenuOpen" class="language-menu" role="menu">
              <button
                v-for="language in languageOptions"
                :key="language.code"
                class="language-option"
                :class="{ active: selectedLanguage === language.code }"
                type="button"
                role="menuitem"
                :aria-label="language.label"
                @click="chooseLanguage(language.code)"
              >
                <img :src="flagSrc(language.code)" :alt="language.label" />
              </button>
            </div>
          </div>
          <Button :label="t('call_staff')" icon="pi pi-bell" size="small" severity="secondary" outlined class="staff-btn" :loading="callingStaff" @click="requestStaff" />
          <Tag :severity="canOrder ? 'success' : 'danger'" :value="canOrder ? t('open_order') : t('closed_order')" class="status-tag" />
        </div>
      </header>

      <section v-if="pendingSubmit" class="status-banner">
        <div>
          <strong>{{ t("pending_order") }}</strong>
          <span>
            {{ t("updated_latest") }} {{ pendingUpdatedText || "-" }}
            <template v-if="pendingSubmit.attempts"> · {{ pendingSubmit.attempts }} {{ t("pending_attempts") }}</template>
          </span>
          <small v-if="pendingSubmit.lastError">{{ pendingSubmit.lastError }}</small>
        </div>
        <div class="status-banner-actions">
          <Button :label="t('retry_submit')" icon="pi pi-refresh" class=" status-banner2" size="small" :loading="submitting" @click="retryPendingSubmit" />
          <Button :label="t('check_status')" severity="secondary" text size="small" @click="checkPendingStatus" />
        </div>
      </section>

      <Tabs v-model:value="activeTab" class="order-tabs">
        <TabList>
          <Tab value="menu">
            <i class="pi pi-book"></i>
            {{ t("menu") }}
          </Tab>
          <Tab value="cart">
            <i class="pi pi-shopping-cart"></i>
            {{ t("cart") }}
            <Badge v-if="cartQty" :value="cartQty" />
          </Tab>
          <Tab value="orders">
            <i class="pi pi-receipt"></i>
            {{ t("orders") }}
          </Tab>
        </TabList>

        <TabPanels>
          <TabPanel value="menu">
            <div class="menu-sticky">
              <div class="sticky-tools">
                <div class="search-box">
                  <i class="pi pi-search search-icon"></i>
                  <InputText v-model="search" :placeholder="t('search_food')" @keyup.enter="loadProducts()" />
                  <button v-if="search" class="search-clear" type="button" :aria-label="t('close')" @click="clearSearch">
                    <i class="pi pi-times"></i>
                  </button>
                </div>
                <Button icon="pi pi-search" :aria-label="t('search')" class="filter-btn" @click="loadProducts()" />
              </div>

              <div class="category-strip">
                
                <Button
                  v-for="category in categories"
                  :key="categoryKey(category)"
                  :label="categoryName(category)"
                  :outlined="selectedCategory !== categoryKey(category)"
                  size="small"
                  @click="chooseCategory(category)"
                />
              </div>
            </div>

            <div v-if="loadingProducts" class="inline-loading">
              <ProgressSpinner style="width: 32px; height: 32px" />
              <span>{{ t("loading_products") }}</span>
            </div>

            <div v-else class="product-list">
              <article v-for="product in products" :key="product.barcode" class="product-row" :class="{ 'sold-out': productIsSoldOut(product) }">
                <button class="product-media" type="button" :disabled="!canOrder || productIsSoldOut(product)" @click="openProduct(product)">
                  <img v-if="imageOf(product)" :src="imageOf(product)" :alt="productName(product)" />
                  <div v-else class="product-image-empty">
                    <i class="pi pi-image"></i>
                  </div>
                  <span v-if="productIsSoldOut(product)" class="sold-out-overlay">{{ t("sold_out") }}</span>
                </button>
                <div class="product-copy">
                  <strong>{{ productName(product) }}</strong>
                  <div class="product-meta">
                    <span>{{ unitName(product) || product.barcode }}</span>
                    <span v-if="productStockText(product)">{{ productStockText(product) }}</span>
                    <span v-if="productIsSoldOut(product)" class="sold-out-badge">{{ t("sold_out") }}</span>
                  </div>
                  <div class="product-price">{{ money(priceOf(product)) }}</div>
                </div>
                <div class="product-actions">
                  <div class="quick-stepper">
                    <Button
                      icon="pi pi-minus"
                      severity="secondary"
                      rounded
                      outlined
                      :aria-label="t('quantity')"
                      :disabled="Boolean(pendingSubmit) || productCartQty(product) <= 0"
                      @click="quickRemoveProduct(product)"
                    />
                    <strong>{{ productCartQty(product) }}</strong>
                    <Button icon="pi pi-plus" rounded :aria-label="t('quantity')" :disabled="!productCanOrder(product)" @click="quickAddProduct(product)" />
                  </div>
                  <div v-if="hasProductOptions(product)" class="">
                    <Button
                      icon="pi pi-list-check"
                      rounded
                      :disabled="!productCanOrder(product)"
                      @click="openProduct(product)"
                    />
                  </div>
                </div>
              </article>

              <div v-if="!products.length" class="empty-block">
                <i class="pi pi-search"></i>
                <p>{{ t("no_products") }}</p>
              </div>
            </div>

            <button v-if="cartQty" class="menu-cart-bar" type="button" @click="activeTab = 'cart'">
              <span class="menu-cart-icon">
                <i class="pi pi-shopping-cart"></i>
                <small>{{ cartQty }}</small>
              </span>
              <div class="menu-cart-copy">
                <strong>{{ t("cart_items") }}</strong>
                <span>{{ cartQty }} {{ t("item_count") }}</span>
              </div>
              <div class="menu-cart-right">
                <strong class="menu-cart-total">{{ money(cartTotal) }}</strong>
              </div>
            </button>
          </TabPanel>

          <TabPanel value="cart">
            <div class="cart-list">
              <article v-for="line in cart" :key="line.lineId" class="cart-line">
                <div class="cart-line-top">
                  <div class="cart-line-media">
                    <img v-if="imageOf(line.product)" :src="imageOf(line.product)" :alt="productName(line.product)" />
                    <div v-else class="product-image-empty"><i class="pi pi-image"></i></div>
                  </div>
                  <div class="cart-line-info">
                    <strong>{{ productName(line.product) }}</strong>
                    <small v-if="selectedOptionText(line.options)">
                      {{ selectedOptionText(line.options) }}
                    </small>
                    <small v-if="line.remark">{{ line.remark }}</small>
                  </div>
                  <Button icon="pi pi-trash" severity="danger" text rounded class="cart-trash" :aria-label="t('close')" :disabled="Boolean(pendingSubmit)" @click="removeLine(line.lineId)" />
                </div>
                <div class="cart-line-bottom">
                  <div class="cart-stepper">
                    <button type="button" :aria-label="t('quantity')" :disabled="Boolean(pendingSubmit)" @click="updateLineQty(line, line.qty - 1)">
                      <i class="pi pi-minus"></i>
                    </button>
                    <strong>{{ line.qty }}</strong>
                    <button type="button" :aria-label="t('quantity')" :disabled="Boolean(pendingSubmit) || !canIncreaseLineQty(line)" @click="updateLineQty(line, line.qty + 1)">
                      <i class="pi pi-plus"></i>
                    </button>
                  </div>
                  <Button :label="t('edit')" icon="pi pi-pencil" outlined class="cart-edit-btn" :disabled="Boolean(pendingSubmit)" @click="openProduct(line.product, line)" />
                  <strong class="cart-line-price">{{ money(lineAmount(line)) }}</strong>
                </div>
              </article>

              <div v-if="!cart.length" class="empty-block">
                <i class="pi pi-shopping-cart"></i>
                <p>{{ t("no_cart_items") }}</p>
                <Button :label="t('menu')" icon="pi pi-book" @click="activeTab = 'menu'" />
              </div>
            </div>

            <div v-if="cart.length" class="checkout-bar">
              <div class="checkout-copy">
                <span>{{ t("all_items") }} {{ cartQty }} {{ t("item_count") }}</span>
                <strong>{{ money(cartTotal) }}</strong>
              </div>
              <Button :label="t('submit_order')" icon="pi pi-send" class="checkout-btn" :disabled="!canOrder" @click="confirmDialog = true" />
            </div>
          </TabPanel>

          <TabPanel value="orders">
            <div class="orders-summary">
              <div class="orders-summary-item orders-summary-count">
                <span class="orders-summary-icon"><i class="pi pi-clipboard"></i></span>
                <div>
                  <span>{{ t("ordered") }}</span>
                  <strong>{{ orders.length }}</strong>
                </div>
              </div>

              <div class="orders-summary-divider"></div>

              <div class="orders-summary-item orders-summary-total">
                <span class="orders-summary-icon"><i class="pi pi-wallet"></i></span>
                <div>
                  <span>{{ t("ordered_total") }}</span>
                  <strong>{{ money(orderedTotal) }}</strong>
                </div>
              </div>

              <div class="orders-summary-divider"></div>

              <div class="orders-summary-item orders-summary-food">
                <span class="orders-summary-icon"><i class="pi pi-box"></i></span>
                <div>
                  <span>{{ t("food_items") }}</span>
                  <strong>{{ qtyText(orderedFoodQty) }}</strong>
                </div>
              </div>

              <div class="orders-summary-divider"></div>

              <div class="orders-summary-item orders-summary-drink">
                <span class="orders-summary-icon"><i class="pi pi-trophy"></i></span>
                <div>
                  <span>{{ t("drink_items") }}</span>
                  <strong>{{ qtyText(orderedDrinkQty) }}</strong>
                </div>
              </div>

              <div v-if="orderedCanceledQty > 0" class="orders-summary-divider"></div>

              <div v-if="orderedCanceledQty > 0" class="orders-summary-item orders-summary-canceled">
                <span class="orders-summary-icon"><i class="pi pi-times-circle"></i></span>
                <div>
                  <span>{{ t("canceled_items") }}</span>
                  <strong>{{ qtyText(orderedCanceledQty) }}</strong>
                </div>
              </div>

              <Button icon="pi pi-refresh" text rounded style="color: #000 !important" class="orders-refresh-btn" :aria-label="t('retry')" @click="loadOrders" />
            </div>

            <div class="order-sync-note" :class="{ error: orderLoadError }" style="color: #000 !important">
              <i :class="orderLoadError ? 'pi pi-exclamation-triangle' : 'pi pi-clock'"></i>
              <span v-if="orderLoadError">{{ orderLoadError }}</span>
              <span v-else>{{ t("updated_latest") }} {{ lastOrderRefreshText || "-" }}</span>
            </div>

            <article v-for="order in orders" :key="order.guidfixed" class="order-batch">
              <div class="order-batch-head">
                <div>
                  <strong>{{ order.ordernumber }}</strong>
                  <small>
                    {{ timeText(order.submittedat) }} ·
                    {{ orderDeviceText(order.customerdeviceid) }}
                  </small>
                  <div class="order-batch-counts">
                    <span><i class="pi pi-box"></i>{{ t("food_items") }} {{ qtyText(orderFoodQty(order)) }}</span>
                    <span><i class="pi pi-trophy"></i>{{ t("drink_items") }} {{ qtyText(orderDrinkQty(order)) }}</span>
                  </div>
                </div>
                <span class="order-status-pill" :class="order.status">{{ orderStatusText(order.status) }}</span>
              </div>
              <div v-for="item in order.items || []" :key="item.id || item.barcode" class="ordered-item" :class="{ cancelled: itemIsCancelled(item) }">
                <span class="ordered-item-copy">
                  <span>{{ nameOf(item.names) || item.barcode }} x {{ qtyText(Number(item.qty || 0)) }}</span>
                  <small v-if="itemCancelQty(item) > 0">
                    {{ itemIsCancelled(item) ? t("canceled_all", { count: qtyText(itemCancelQty(item)) }) : t("canceled_qty", { count: qtyText(itemCancelQty(item)) }) }}
                  </small>
                  <small v-if="itemProgressText(item)">
                    {{ itemProgressText(item) }}
                  </small>
                </span>
                <strong>{{ money(item.amount) }}</strong>
              </div>
            </article>

            <div v-if="!orders.length" class="empty-block">
              <i class="pi pi-receipt"></i>
              <p>{{ t("no_orders") }}</p>
            </div>
          </TabPanel>
        </TabPanels>
      </Tabs>
    </template>

    <Dialog v-model:visible="productDialog" modal class="product-dialog" :draggable="false" :show-header="false">
      <div v-if="selectedProduct" class="product-detail">
        <div class="detail-hero">
          <button v-if="imageOf(selectedProduct)" class="detail-image-button" type="button" :aria-label="productName(selectedProduct)" @click.stop="imagePreviewDialog = true">
            <img :src="imageOf(selectedProduct)" :alt="productName(selectedProduct)" />
          </button>
          <div v-else class="product-image-empty large"><i class="pi pi-image"></i></div>
          <div class="detail-hero-copy">
            <strong>{{ productName(selectedProduct) }}</strong>
            <span>{{ unitName(selectedProduct) || selectedProduct.barcode }}</span>
            <span v-if="productStockText(selectedProduct, editingLineId)">{{ productStockText(selectedProduct, editingLineId) }}</span>
            <p>{{ money(priceOf(selectedProduct)) }}</p>
          </div>
          <button class="detail-close" type="button" :aria-label="t('close')" @click="productDialog = false">
            <i class="pi pi-times"></i>
          </button>
        </div>

        <section class="detail-section qty-section">
          <label class="field-label">{{ t("quantity") }}</label>
          <div class="detail-qty">
            <button type="button" :aria-label="t('quantity')" @click="changeDraftQty(-1)">
              <i class="pi pi-minus"></i>
            </button>
            <strong>{{ draftQty }}</strong>
            <button type="button" :aria-label="t('quantity')" class="plus" :disabled="!canIncreaseDraftQty()" @click="changeDraftQty(1)">
              <i class="pi pi-plus"></i>
            </button>
          </div>
        </section>

        <section class="detail-section note-section">
          <label class="field-label">{{ t("note") }}</label>
          <Textarea v-model="draftRemark" auto-resize rows="2" :placeholder="t('note')" fluid />
        </section>

        <section v-for="option in draftOptions" :key="option.guid" class="option-group">
          <div class="option-head">
            <strong>{{ nameOf(option.names) }}</strong>
            <span>{{ optionRuleText(option) }}</span>
          </div>
          <small v-if="optionErrors[option.guid]" class="option-error">
            {{ optionErrors[option.guid] }}
          </small>
          <div class="choice-grid">
            <button
              v-for="(choice, choiceIndex) in option.choices"
              :key="choice.guid"
              type="button"
              class="choice-chip"
              :class="{ selected: choice.selected }"
              @click="toggleChoice(option, choiceIndex)"
            >
              <span class="choice-mark" :class="{ single: isSingleChoiceOption(option), selected: choice.selected }"></span>
              <span class="choice-name">{{ nameOf(choice.names) }}</span>
              <small v-if="Number(choice.priceValue || choice.price) > 0"> +{{ money(Number(choice.priceValue || choice.price)) }} </small>
            </button>
          </div>
        </section>
      </div>
      <template #footer>
        <div class="dialog-actions product-dialog-actions">
          <Button :label="t('close')" severity="secondary" outlined @click="productDialog = false" />
          <Button icon="pi pi-shopping-cart" @click="addDraftToCart">
            <template #default> {{ editingLineId ? t("save") : t("add_to_cart") }} {{ money(selectedProductTotal) }} </template>
          </Button>
        </div>
      </template>
    </Dialog>

    <Dialog v-model:visible="imagePreviewDialog" modal class="product-image-dialog" :draggable="false" :show-header="false" :dismissable-mask="true">
      <div v-if="selectedProduct && selectedProductImage" class="product-image-viewer">
        <button class="image-preview-close" type="button" :aria-label="t('close')" @click="imagePreviewDialog = false">
          <i class="pi pi-times"></i>
        </button>
        <img :src="selectedProductImage" :alt="productName(selectedProduct)" />
      </div>
    </Dialog>

    <Dialog v-model:visible="confirmDialog" modal :header="t('confirm_submit')" :draggable="false">
      <p class="confirm-copy">{{ t("confirm_submit_body") }}</p>
      <div class="confirm-total">
        <span style="color: #000; font-weight: 700; font-size: 16px">{{ cartQty }} {{ t("item_count") }}</span>
        <strong>{{ money(cartTotal) }}</strong>
      </div>
      <div class="dialog-actions">
        <Button :label="t('back_to_edit')" severity="secondary" outlined @click="confirmDialog = false" />
        <Button :label="t('confirm_submit')" icon="pi pi-send" :loading="submitting" @click="confirmSubmit" />
      </div>
    </Dialog>
  </main>
</template>
