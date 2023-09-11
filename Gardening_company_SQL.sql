
# QUERY ONE:

 # The company works in a lot of countries, so they want to find out in which country they carry out more operations, taking into account the employees who work there, 
 # the losses there can be due to pending orders, and the hypothetical benefit they can get if they sell all the products they have in stock.

/*/ TASKS /*/

#_________________________________________________________________________________________________________
 
 SELECT COUNT(*), pais, region
   FROM jardineria.cliente 
 GROUP BY pais, region ;

  # First of all, we find out that Madrid (Spain) has proven to be the  area where they mostly work. The company requires only the statistics from the employees woking in 
  # the office (MAD-ES).
  
#_________________________________________________________________________________________________________
  
 SELECT c.nombre_cliente, c.codigo_cliente, CONCAT(e.nombre, '  ',  e.apellido1, '  ',  e.apellido2) AS 'Nombre y Apellidos', e.puesto, e.codigo_oficina
   FROM jardineria.cliente c
   JOIN jardineria.empleado e
	ON c.codigo_empleado_rep_ventas= e.codigo_empleado  
   JOIN jardineria.oficina o
	ON e.codigo_oficina = o.codigo_oficina 
 WHERE o.ciudad = 'Madrid' ;
 
  # We check the employees who are located in Madrid (MAD-ES), their job position and the clients they are working with. We see there are two employees that are working with
  # different clients in Madrid. 
  
#_________________________________________________________________________________________________________
   
 SELECT estado, comentarios, codigo_pedido, codigo_cliente 
   FROM jardineria.pedido
 WHERE codigo_cliente IN ('6', '12', '13', '14', '26', '27') AND estado = 'pendiente' ;

  # This query is to find out all the pending orders with clients in Madrid.
  # Now, I filter the table to find out the pending orders, in other words, those orders that havent not yet been delivered  due to different reasons.
  # This means losses for the company.

 CREATE VIEW clients_in_Madrid_pedido AS 
 SELECT estado, comentarios, codigo_pedido, codigo_cliente 
   FROM jardineria.pedido
 WHERE codigo_cliente IN ('6', '12', '13', '14', '26', '27') ;

 SELECT *
   FROM clients_in_Madrid_pedido ;

  # With this view I can check at any time the status of each order placed by clients from Madrid.
  
#_________________________________________________________________________________________________________
  
 CREATE VIEW Spain_losses_detalle_pedido AS  
 SELECT SUM(losses.`Cantidad total perdida`) AS 'Suma total perdida'
   FROM (
    SELECT SUM(cantidad * precio_unidad) AS 'Cantidad total perdida'
      FROM jardineria.detalle_pedido
    WHERE codigo_pedido IN ('90', '94', '50', '52','57','54')
    GROUP BY codigo_pedido
 ) AS losses;  

 SELECT *
   FROM Spain_losses_detalle_pedido ;
  
  # I use a subquery to find out the total losses due to pending orders, I do calculate the amount of products ordered by the clients * precio_unidad.
  # I create a view to make easier future queries.
  # If the status of pending order doesnt' change, it will mean a loss of 11488 €.


#_________________________________________________________________________________________________________

 SELECT m.codigo_pedido, p.codigo_producto, p.nombre, p.cantidad_en_stock, p.precio_venta, p.precio_proveedor,  (p.cantidad_en_stock * (p.precio_venta-p.precio_proveedor)) AS "Beneficio Potencial"
   FROM jardineria.producto p
   JOIN jardineria.detalle_pedido d
    ON p.codigo_producto = d.codigo_producto
   JOIN clients_in_Madrid_pedido m
    ON d.codigo_pedido = m.codigo_pedido ;
   
  # I do calculate the total benefit of each product in stock.

 CREATE VIEW beneficio_2022_stock_producto AS
 SELECT SUM(p.cantidad_en_stock * (p.precio_venta-p.precio_proveedor)) AS "Beneficio Potencial"
   FROM jardineria.producto p
   JOIN jardineria.detalle_pedido d
    ON p.codigo_producto = d.codigo_producto
   JOIN clients_in_Madrid_pedido m
    ON d.codigo_pedido = m.codigo_pedido ;

  # I'll create a view to see the total profit. Now I can check the total profit whenever I need to.

  # THE VIEW -->
 SELECT *
   FROM beneficio_2022_stock_producto ;
   
  # The profit if all products in stock are sold is 25054 €.
   
#_________________________________________________________________________________________________________
#_________________________________________________________________________________________________________

# QUERY TWO:

 # The client wants me to find out their market in The USA ( The benefits from delivered orders so far, the hypothetical benefit from products in stock, and the 
 # the total profits we could get in 2022).
 
/*/ TASKS /*/

#_________________________________________________________________________________________________________

 CREATE VIEW USA_clients AS 
 SELECT codigo_cliente, nombre_cliente, nombre_contacto, apellido_contacto, telefono, ciudad, codigo_empleado_rep_ventas, limite_credito
   FROM jardineria.cliente
 WHERE pais = 'USA' ;

  # The view --->
 SELECT *
   FROM USA_clients ;
  
  # I gather all the USA clients and I create a view.
  
#_________________________________________________________________________________________________________

 SELECT c.nombre_cliente, c.codigo_cliente,  c.pais,d.codigo_producto, d.cantidad , d.precio_unidad, SUM(d.cantidad* d.precio_unidad) AS 'BENEFICIO TOTAL DE CADA PRODUCTO'
   FROM jardineria.cliente c
   JOIN jardineria.pedido p
   ON c.codigo_cliente = p.codigo_cliente
   JOIN jardineria.detalle_pedido d
    ON p.codigo_pedido = d.codigo_pedido
 WHERE c.pais = "USA" and p.estado = 'Entregado'
 GROUP BY c.nombre_cliente, c.codigo_cliente,  c.pais,d.codigo_producto, d.cantidad , d.precio_unidad ;  
 
  # Once, we have all the info from the clients, I filter the table by delivered orders and 'USA' to calculate the benefit for each product.
  
#_________________________________________________________________________________________________________ 

  # This is the same operation but only showing the total profit and I create a view to save the info.
  
 CREATE VIEW total_usa_profit_detalle_pedido AS
 SELECT  SUM(d.cantidad* d.precio_unidad) AS 'BENEFICIO TOTAL'
   FROM jardineria.cliente c
   JOIN jardineria.pedido p
    ON c.codigo_cliente = p.codigo_cliente
   JOIN jardineria.detalle_pedido d
    ON p.codigo_pedido = d.codigo_pedido
 WHERE c.pais = "USA" and p.estado = 'Entregado' ;

  # This is the view --->
 SELECT *
   FROM total_usa_profit_detalle_pedido ;
   
  # The total profit obtained by delivered orders is 27732 €.
  
#_________________________________________________________________________________________________________

 SELECT (SELECT * FROM total_usa_profit_detalle_pedido) + (SELECT * FROM total_profit_stock_producto ) AS " BENEFICIO TOTAL ESTIMADO 2022 EN USA" ;

  # Finally, I add the benefit I I have made from the delivered orders plus all the benefit I can make if I sell all products in stock, which is 62629 €.
  
#_________________________________________________________________________________________________________
#_________________________________________________________________________________________________________

# QUERY THREE:

  # The company asks me to complete the information by giving them some specific details related to different departments.

/*/ TASKS /*/

#_________________________________________________________________________________________________________

  # The client needs to check how many products they have in stock of each type :
  
 CREATE VIEW prodxcategory_producto AS
 SELECT gama, SUM(cantidad_en_stock) AS "PRODUCTOS EN STOCK POR CATEGORÍA"
   FROM jardineria.producto
 WHERE gama IN ('Herramientas' , 'Aromáticas', 'Frutales', 'Ornamentales') 
 GROUP BY gama ;

  # VIEW ---> 
 SELECT *
 FROM prodxcategory_producto ;
 
  # Products are divided into four categories and we notice 'Frutales' is the largest category. 
  
#_________________________________________________________________________________________________________

 SELECT SUM(cantidad_en_stock*(precio_venta - precio_proveedor)) AS "BENEFICIO POTENCIAL VENTA DEL STOCK"
   FROM jardineria.producto ;
   
  # The profit we can obtain is enormous --> 102071.00 €
  
#_________________________________________________________________________________________________________
  
  
 SELECT gama, SUM(cantidad_en_stock*(precio_venta - precio_proveedor)) AS 'BENEFICIO POR CATEGORÍA'
   FROM jardineria.producto 
 GROUP BY gama ;
 
  # This is the benefit we could obtain per category (Aromáticas (1400€), Frutales (58415€), Herramientas (90€), Ornamentales (42166€)).
 
  
#_________________________________________________________________________________________________________

 SELECT codigo_producto, nombre
   FROM jardineria.producto
 WHERE proveedor = 'Viveros EL OASIS' and cantidad_en_stock < 50 ;
 
  # I'm asked to find out the total amount of products in stock that belong to 'Viveros EL OASIS', and they have less than 50 product in stock.
  # There are 13 of them.
  
#_________________________________________________________________________________________________________

 SELECT codigo_producto, MAX(precio_unidad)
   FROM jardineria.detalle_pedido
 WHERE numero_linea = '3'
 GROUP BY codigo_producto,precio_unidad
  HAVING MAX(precio_unidad) >= '70'
  ORDER BY precio_unidad DESC ; 
  
  SELECT nombre, gama
FROM jardineria.producto
WHERE codigo_producto = 'OR-247';
  
  # I'm asked to find out those products that belong to 'numero_linea = 3'; Also, those that have a price equal to or greater than 70; Sorted by higher price.
  # The query gives us 6 products that meet the requirements; Now, I'm asked to find out the name of the most expensive one.
  # Then, with a small query I check the name of the product (OR-247) that costs 462 €, which is 'Trachycarpus Fortunei'.
  
#_________________________________________________________________________________________________________
   