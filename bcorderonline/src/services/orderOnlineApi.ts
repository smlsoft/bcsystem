import type {
  ApiResponse,
  OrderBatch,
  ProductBarcode,
  ProductCategory,
  SubmitOrderItem,
  TableSession,
} from '../types';

const baseUrl = (import.meta.env.VITE_ORDERONLINE_API_URL || '').replace(/\/$/, '');

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${baseUrl}${path}`, {
    ...init,
    headers: {
      'content-type': 'application/json',
      ...(init?.headers ?? {}),
    },
  });
  const payload = (await response.json().catch(() => ({}))) as ApiResponse<T>;
  if (!response.ok || payload.success === false) {
    throw new Error(payload.message || `Request failed: ${response.status}`);
  }
  return (payload.data ?? (payload as T)) as T;
}

export function getSession(token: string): Promise<TableSession> {
  return request<TableSession>(`/order-online/public/session/${encodeURIComponent(token)}`);
}

export function listCategories(token: string): Promise<ProductCategory[]> {
  return request<ProductCategory[]>(
    `/order-online/public/session/${encodeURIComponent(token)}/category?page=1&limit=100`,
  );
}

export function listProducts(
  token: string,
  params: {
    q?: string;
    categoryCode?: string;
    groupCode?: string;
    barcodes?: string[];
    page?: number;
    limit?: number;
  },
): Promise<ProductBarcode[]> {
  const search = new URLSearchParams();
  search.set('page', String(params.page ?? 1));
  search.set('limit', String(params.limit ?? 100));
  search.set('isalacarte', 'true');
  if (params.q) search.set('q', params.q);
  if (params.categoryCode) search.set('categorycode', params.categoryCode);
  if (params.groupCode) search.set('groupcode', params.groupCode);
  if (params.barcodes?.length) search.set('barcodes', JSON.stringify(params.barcodes));
  return request<ProductBarcode[]>(
    `/order-online/public/session/${encodeURIComponent(token)}/product-barcode?${search.toString()}`,
  );
}

export function getProduct(token: string, barcode: string): Promise<ProductBarcode> {
  return request<ProductBarcode>(
    `/order-online/public/session/${encodeURIComponent(token)}/product-barcode/${encodeURIComponent(barcode)}`,
  );
}

export function validateCart(
  token: string,
  idempotencyKey: string,
  customerDeviceId: string,
  items: SubmitOrderItem[],
): Promise<OrderBatch> {
  return request<OrderBatch>(
    `/order-online/public/session/${encodeURIComponent(token)}/cart/validate`,
    {
      method: 'POST',
      body: JSON.stringify({ idempotencykey: idempotencyKey, customerdeviceid: customerDeviceId, items }),
    },
  );
}

export function submitOrder(
  token: string,
  idempotencyKey: string,
  customerDeviceId: string,
  items: SubmitOrderItem[],
): Promise<OrderBatch> {
  return request<OrderBatch>(`/order-online/public/session/${encodeURIComponent(token)}/orders`, {
    method: 'POST',
    body: JSON.stringify({ idempotencykey: idempotencyKey, customerdeviceid: customerDeviceId, items }),
  });
}

export function listSessionOrders(token: string): Promise<OrderBatch[]> {
  return request<OrderBatch[]>(
    `/order-online/public/session/${encodeURIComponent(token)}/orders`,
  );
}

export function callStaff(token: string, customerDeviceId: string): Promise<unknown> {
  return request<unknown>(`/order-online/public/session/${encodeURIComponent(token)}/caller`, {
    method: 'POST',
    body: JSON.stringify({ customerdeviceid: customerDeviceId }),
  });
}
