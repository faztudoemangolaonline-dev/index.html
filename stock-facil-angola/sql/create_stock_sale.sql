create or replace function public.create_stock_sale(
  p_product_id uuid,
  p_quantity numeric,
  p_customer_id uuid default null,
  p_paid_amount numeric default 0,
  p_discount numeric default 0,
  p_notes text default ''
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_product public.products%rowtype;
  v_sale_id uuid;
  v_subtotal numeric(14,2);
  v_total numeric(14,2);
  v_status text;
begin
  if v_user is null then raise exception 'Sessão inválida'; end if;
  if p_quantity is null or p_quantity <= 0 then raise exception 'Quantidade inválida'; end if;
  if p_discount is null or p_discount < 0 or p_paid_amount is null or p_paid_amount < 0 then raise exception 'Valor inválido'; end if;
  select * into v_product from public.products
    where id = p_product_id and user_id = v_user and active = true
    for update;
  if not found then raise exception 'Produto não encontrado'; end if;
  if v_product.quantity < p_quantity then raise exception 'Stock insuficiente'; end if;
  if p_customer_id is not null and not exists(select 1 from public.customers where id=p_customer_id and user_id=v_user) then
    raise exception 'Cliente inválido';
  end if;
  v_subtotal := round(p_quantity * v_product.sale_price,2);
  v_total := greatest(v_subtotal - p_discount,0);
  if p_paid_amount > v_total then raise exception 'O valor recebido não pode exceder o total'; end if;
  v_status := case when p_paid_amount >= v_total then 'paid' when p_paid_amount > 0 then 'partial' else 'credit' end;
  insert into public.sales(user_id,customer_id,sale_number,subtotal,discount,total,paid_amount,status,notes)
  values(v_user,p_customer_id,'SF-'||to_char(now(),'YYYYMMDD-HH24MISS')||'-'||upper(substr(gen_random_uuid()::text,1,4)),v_subtotal,p_discount,v_total,p_paid_amount,v_status,coalesce(p_notes,''))
  returning id into v_sale_id;
  insert into public.sale_items(user_id,sale_id,product_id,product_name,quantity,unit_price,unit_cost,line_total)
  values(v_user,v_sale_id,v_product.id,v_product.name,p_quantity,v_product.sale_price,v_product.cost_price,v_total);
  update public.products set quantity=quantity-p_quantity where id=v_product.id and user_id=v_user;
  if p_paid_amount > 0 then
    insert into public.payments(user_id,sale_id,amount,method,note)
    values(v_user,v_sale_id,p_paid_amount,'cash','Pagamento no acto da venda');
  end if;
  return v_sale_id;
end;
$$;
revoke all on function public.create_stock_sale(uuid,numeric,uuid,numeric,numeric,text) from public, anon;
grant execute on function public.create_stock_sale(uuid,numeric,uuid,numeric,numeric,text) to authenticated;