DROP DATABASE CellPhoneS;
CREATE DATABASE CellPhoneS;
USE CellPhoneS;

CREATE TABLE Brand (
	BrandID INT AUTO_INCREMENT  PRIMARY KEY,
	BrandName VARCHAR (255) NOT NULL
);

CREATE TABLE Category (
	CategoryID INT AUTO_INCREMENT PRIMARY KEY,
	CategoryName VARCHAR (255) NOT NULL
);


CREATE TABLE Accounts (
	UserID INT AUTO_INCREMENT  PRIMARY KEY,
	UserName VARCHAR (255) NOT NULL,
	PassWordd VARCHAR (255) NOT NULL,
	FirstName VARCHAR (25) NOT NULL,
	LastName VARCHAR (255) NOT NULL,
	Email VARCHAR (255) NOT NULL,
	Phone VARCHAR (10) NOT NULL,
	Address VARCHAR (255) NOT NULL,
	AccountType ENUM('Buyer', 'Seller') NOT NULL
);

CREATE TABLE Customers (
	CustomerID INT PRIMARY KEY,
    FOREIGN KEY (CustomerID) REFERENCES Accounts(UserID) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE Suppliers (
	SupplierID INT PRIMARY KEY,
	BankName VARCHAR (255) NOT NULL,
	BankAccountNumber DECIMAL(10,0) NOT NULL,	
    FOREIGN KEY (SupplierID) REFERENCES Accounts(UserID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Products (
	ProductID INT AUTO_INCREMENT  PRIMARY KEY,
	ProductName VARCHAR (255) NOT NULL,
	ProductDescription VARCHAR (255) NOT NULL,
	BrandID INT NOT NULL,
	CurrentPrice INT NOT NULL,
    Origin VARCHAR (255) NOT NULL,	
    ImageURL VARCHAR (255) NOT NULL,	
	FOREIGN KEY (BrandID) REFERENCES Brand(BrandID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Supply (
	SupplierID INT ,
	ProductID INT,
    QuantityInStock INT NOT NULL,
	PRIMARY KEY (SupplierID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Orders (
	OrderID INT AUTO_INCREMENT PRIMARY KEY,
	CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    DeliverDate DATE ,
	OrderStatus tinyint NOT NULL,
	-- Processing==1,Shipping==2,Delivered==3, Cancelled==4
	FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE CategoryDetail (
	CategoryID INT,
	ProductID INT,
    PRIMARY KEY (CategoryID, ProductID),
	FOREIGN KEY (CategoryID) REFERENCES Category (CategoryID) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ProductID) REFERENCES products (ProductID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Ordersdetail (
    OrderID INT ,
    ProductID INT ,
    SupplierID INT NOT NULL ,
    Quantity INT NOT NULL,
    UnitPrice INT NOT NULL,
    Discount DECIMAL (4, 2) NOT NULL DEFAULT 0,
	PRIMARY KEY (OrderID, ProductID),
	FOREIGN KEY (OrderID) REFERENCES Orders (OrderID) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ProductID) REFERENCES products (ProductID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers (SupplierID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Productsdetail (
    CustomerID INT ,
    ProductID INT ,
    Rating DECIMAL (4, 1),
    Review VARCHAR (255),	
	PRIMARY KEY (CustomerID, ProductID),
	FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ProductID) REFERENCES Products (ProductID) ON DELETE CASCADE ON UPDATE CASCADE
);



 -- ------------------------------------------------------------------------
-- cau 2 a
select a.ProductName as `Ten san pham`,d.BrandName as `Ten thuong hieu`,c.CategoryName as `Ten danh muc`,g.FirstName as `Ho nha cung cap` ,g.LastName as `Ten nha cung cap` 
from Products as a join CategoryDetail as b on a.ProductID=b.ProductID 
join Category as c on c.CategoryID=b.CategoryID join Brand as d on d.BrandID=a.BrandID 
join Supply as e on e.ProductId=a.ProductID join Suppliers as f on f.SupplierID=e.SupplierID 
join Accounts as g on g.UserID=f.SupplierID
where a.ProductID  in
(select a.ProductID from  Ordersdetail as a 
join Orders as b on b.OrderID=a.OrderID where b.OrderStatus = '3')
;
-- cau 2 b
select b.BrandName as `Thuong hieu`,sum(e.QuantityInstock) as `So luong san pham ton kho cua moi thuong hieu`
from Products as a join Brand as b on b.BrandID=a.BrandID 
join Supply as e on e.ProductId=a.ProductID join Suppliers as f on f.SupplierID=e.SupplierID 
group by b.BrandID;

-- cau 2 c
select l.BrandName as `Ten thuong hieu`, m.ProductName as `Ten san pham`, temp.AvgRating2 as `Diem danh gia trung binh` from Products as m join  Brand as l on l.BrandID=m.BrandID 
 join (select x.ProductID,x.BrandID , AVG(y.Rating) AS AvgRating2
from Products as x join ProductsDetail as y on x.ProductID=y.ProductID join  Brand as z on z.BrandID=x.BrandID 
group by x.ProductID,x.BrandID 
having (x.BrandId,AvgRating2) in (select max_ratings.BrandID, max(AvgRating)
from (select a.ProductID,a.BrandID , AVG(b.Rating) AS AvgRating
from Products as a join ProductsDetail as b on a.ProductID=b.ProductID join  Brand as c on c.BrandID=a.BrandID 
group by a.ProductID,a.BrandID
order by AvgRating  DESC) as max_ratings group by max_ratings.BrandID) ) as temp on temp.BrandId=m.BrandID and temp.ProductID=m.ProductID;

-- cau 2 d
-- điều chỉnh dữ liệu những đơn hàng được bán bởi XYZ trong tháng 1 2024 luôn có số lượng bé hơn 10
-- xem insert bang orderdetail de xem so luong của XYZ ban đuoc ( ID của XYZ = 7)
select temp.ProductName as `Ten san pham` ,temp.soluongbanduoc as `So luong ban duoc`
from
(select b.ProductID , c.ProductName  ,sum(b.Quantity) as soluongbanduoc
from orders as a join ordersdetail as b on a.orderid = b.orderid join products as c on c.productID=b.ProductID
where a.orderstatus=3  and month(a.OrderDate) =1 and year(a.OrderDate) =2024  and b.SupplierID = (select n.UserID from Accounts as n where n.UserName='XYZ') 
group by b.ProductID 
having soluongbanduoc <10) as temp;
-- cay 2 e


select month(m.OrderDate) `Thang (2023)`,k.ProductName as `Ten san pham`,sum(n.quantity) as `So luong ban duoc`
from orders as m 
join ordersdetail as n on m.orderid = n.orderid 
join products as l on l.productID=n.ProductID
join Products as k on k.ProductID=l.ProductID
where (month(m.OrderDate), (SELECT SUM(b.Quantity) 
         FROM orders AS a 
         JOIN ordersdetail AS b ON a.orderid = b.orderid 
         WHERE a.orderstatus = 3 
         AND YEAR(a.OrderDate) = 2023 
         AND MONTH(a.OrderDate) = MONTH(m.OrderDate)
         AND b.ProductID = n.ProductID)) in
		(select MaxTotal.Month, max(MaxTotal.TotalQuantity)
		from
			(select c.ProductID, month(a.OrderDate) as Month,sum(b.Quantity) as TotalQuantity
			from orders as a join ordersdetail as b on a.orderid = b.orderid 
			join products as c on c.productID=b.ProductID
			where a.orderstatus=3  and year(a.OrderDate) =2023  
			group by c.ProductID,month(a.OrderDate)
			order by  TotalQuantity desc) as MaxTotal
		group by  MaxTotal.Month
		having max(MaxTotal.TotalQuantity))
group by n.ProductID,month(m.OrderDate),k.ProductName
order by month(m.OrderDate) asc;

-- cay 2 f

select months.month as `Thang`, IFNULL(monthly_data.TotalPrice, 0) as `Tong doanh thu thang`
from (
    select 1 AS month
    union select 2 union select 3 union select 4 union select 5 union select 6 union
    select 7 union select 8 union select 9 union select 10 union select 11 union select 12
) as months
left join (
    select month(a.OrderDate) AS OrderMonth, SUM(b.UnitPrice*b.Quantity) as TotalPrice
    from orders as a 
    join ordersdetail as b on a.orderid = b.orderid 
    join products as c on c.productID = b.ProductID
    where a.orderstatus = 3 and year(a.OrderDate) = 2023 
    and b.SupplierID = (SELECT n.UserID from Accounts as n where n.UserName = 'XYZ')
    group by month(a.OrderDate), b.SupplierID
) as monthly_data on months.month = monthly_data.OrderMonth
group by months.month, monthly_data.TotalPrice;





