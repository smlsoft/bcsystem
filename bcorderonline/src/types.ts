export type LocalizedName = {
  code?: string;
  name?: string;
  names?: string;
  text?: string;
  lang?: string;
};

export type ApiResponse<T> = {
  success?: boolean;
  data?: T;
  pagination?: {
    page?: number;
    perPage?: number;
    total?: number;
    totalPage?: number;
  };
  message?: string;
};

export type TableSession = {
  sessionid: number;
  shopid: string;
  tablenumber: string;
  tableguid?: string;
  status: string;
  canorder: boolean;
  token?: string;
  qrurl?: string;
  openedat?: string;
  expiresat?: string;
};

export type ProductCategory = {
  guidfixed?: string;
  code?: string;
  codelist?: Array<{
    code?: string;
    barcode?: string;
    unitcode?: string;
    names?: LocalizedName[] | string;
  }>;
  names?: LocalizedName[] | string;
  name?: string;
  groupnumber?: number;
  xsorts?: Array<{ code?: string; xorder?: number }>;
};

export type ProductChoice = {
  guid: string;
  names: LocalizedName[] | string;
  price: string | number;
  priceValue?: number;
  selected?: boolean;
  isdefault?: boolean;
  qty?: number;
  refbarcode?: string;
  refproductcode?: string;
  refunitcode?: string;
  barcode?: string;
};

export type ProductOption = {
  guid: string;
  choicetype: number;
  maxselect: number;
  minselect?: number;
  names: LocalizedName[] | string;
  choices: ProductChoice[];
};

export type ProductBarcode = {
  guidfixed?: string;
  guid_fixed?: string;
  barcode: string;
  itemcode?: string;
  item_code?: string;
  itemguid?: string;
  item_guid?: string;
  names?: LocalizedName[] | string;
  name?: string;
  unitnames?: LocalizedName[] | string;
  itemunitnames?: LocalizedName[] | string;
  item_unit_names?: LocalizedName[] | string;
  itemunitcode?: string;
  item_unit_code?: string;
  unitcode?: string;
  categorycode?: string;
  category_code?: string;
  foodtype?: number;
  food_type?: number;
  groupcode?: string;
  prices?: Array<{ keynumber?: number; keyNumber?: number; price?: number }>;
  imageuri?: string;
  imageurl?: string;
  images_url?: string;
  image_url?: string;
  options?: ProductOption[];
  options_json?: string;
  orderstatus?: number;
  orderautostock?: boolean | number;
  orderdisable?: boolean | number;
  qtybalance?: number;
  qtystart?: number;
  qtymin?: number;
  isavailablefororder?: boolean;
  issoldout?: boolean;
  unavailablereason?: string;
};

export type CartLine = {
  lineId: string;
  product: ProductBarcode;
  qty: number;
  remark: string;
  options: ProductOption[];
};

export type PendingSubmit = {
  idempotencyKey: string;
  customerDeviceId: string;
  items: SubmitOrderItem[];
  cartSnapshot: CartLine[];
  attempts: number;
  lastError: string;
  updatedAt: string;
};

export type SubmitOrderItem = {
  barcode: string;
  qty: number;
  optionselected: ProductOption[];
  remark: string;
};

export type OrderBatch = {
  id: number;
  guidfixed: string;
  ordernumber: string;
  idempotencykey?: string;
  customerdeviceid?: string;
  status: string;
  tablenumber: string;
  itemcount: number;
  totalqty: number;
  totalamount: number;
  submittedat: string;
  failedreason?: string;
  items?: OrderBatchItem[];
};

export type OrderBatchItem = {
  id?: number;
  barcode: string;
  names?: LocalizedName[] | string;
  unitnames?: LocalizedName[] | string;
  qty: number;
  orderqty?: number;
  cancelqty?: number;
  iscancelled?: boolean;
  servedqty?: number;
  servedsuccess?: boolean;
  kdssuccess?: boolean;
  price: number;
  amount: number;
  foodtype?: number;
  food_type?: number;
  optionselected?: ProductOption[];
  remark?: string;
};
