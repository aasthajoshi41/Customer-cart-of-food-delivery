
CREATE TABLE CategoryMaster (
    CategoryId INT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL,
    CategoryDescription VARCHAR(100) NOT NULL,
    IsActive BIT NOT NULL,
    CreatedDate DATETIME NOT NULL
);

CREATE TABLE ItemMaster (
    ItemId INT PRIMARY KEY,
    CategoryId INT,
    ItemName VARCHAR(100) NOT NULL,
    ItemDescription VARCHAR(100),
    Price DECIMAL(10,2) NOT NULL,
    Gst DECIMAL(10,2) NOT NULL,
    IsActive BIT NOT NULL,
    CreatedDate DATETIME NOT NULL,
    FOREIGN KEY (CategoryId) REFERENCES CategoryMaster(CategoryId)
);

CREATE TABLE CoupenMaster (
    CouponedId INT PRIMARY KEY,
    Couponetext VARCHAR(100),
    DiscountPercentage DECIMAL(10,2) NOT NULL,
    ExpiryDate DATETIME NOT NULL
);

CREATE TABLE OrderMaster (
    Ordered INT IDENTITY(1001, 1) PRIMARY KEY,
    Deliverycharge INT NOT NULL,
    CoupenAmount DECIMAL(10,2) NOT NULL,  
    SubTotal DECIMAL(10,2) NOT NULL,
    Total DECIMAL(10,2) NOT NULL,
    OrderedDate DATETIME NOT NULL
);

CREATE TABLE OrderDetails (
    OrderDetailsId INT IDENTITY(1001, 1) PRIMARY KEY,
    Ordered INT,
    ItemId INT NOT NULL, 
    Quantity INT NOT NULL,
    Total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (Ordered) REFERENCES OrderMaster(Ordered),
    FOREIGN KEY (ItemId) REFERENCES ItemMaster(ItemId)
);


INSERT INTO CategoryMaster (CategoryId, CategoryName, CategoryDescription, IsActive, CreatedDate)
VALUES 
(1, 'Fast Food', 'Quick meals and street food', 1, '2025-06-02'),
(2, 'Healthy', 'Salads, smoothies, and organic meals', 1, '2025-06-02');

INSERT INTO ItemMaster (ItemId, CategoryId, ItemName, ItemDescription, Price, Gst, IsActive, CreatedDate)
VALUES
(101, 1, 'Burger', 'Cheesy chicken burger', 180.00, 5.00, 1, '2025-06-02'),
(102, 2, 'French Fries', 'Crispy golden fries', 90.00, 5.00, 1, '2025-06-02'),
(103, 1, 'Caesar Salad', 'Fresh salad with dressing', 140.00, 5.00, 1, '2025-06-02'),
(104, 2, 'Fruit Smoothie', 'Mixed berries and yogurt', 160.00, 5.00, 1, '2025-06-02');

INSERT INTO CoupenMaster (CouponedId, Couponetext, DiscountPercentage, ExpiryDate)
VALUES
(201, 'FAST20', 20.00, '2025-10-31'),
(202, 'HEALTHY10', 10.00, '2025-12-01'),
(203, 'EXPIRED10', 10.00, '2024-12-31'),  
(204, 'FREEDRINK', 100.00, '2025-07-15');

-- show all tables 
EXEC sp_msforeachtable 'select * from ?'


--SP to insert data into 3 tables

CREATE PROCEDURE Insertintotable(

    @CategoryId INT, @CategoryName VARCHAR(100), @CategoryDescription VARCHAR(100), @CategoryIsActive BIT, @CategoryCreatedDate DATETIME,

    @CouponId INT, @CouponText VARCHAR(100), @DiscountPercentage DECIMAL(10,2), @ExpiryDate DATETIME,

    @ItemId INT, @ItemCategoryId INT, @ItemName VARCHAR(100),  @ItemDescription VARCHAR(100), @Price DECIMAL(10,2),  @Gst DECIMAL(10,2), @ItemIsActive BIT,  @ItemCreatedDate DATETIME
 )
AS
BEGIN
    -- Insert into CategoryMaster
    INSERT INTO CategoryMaster (CategoryId, CategoryName, CategoryDescription, IsActive, CreatedDate)
    VALUES (@CategoryId, @CategoryName, @CategoryDescription, @CategoryIsActive, @CategoryCreatedDate);

    -- Insert into CoupenMaster
    INSERT INTO CoupenMaster (CouponedId, Couponetext, DiscountPercentage, ExpiryDate)
    VALUES (@CouponId, @CouponText, @DiscountPercentage, @ExpiryDate);

    -- Insert into ItemMaster
    INSERT INTO ItemMaster (ItemId, CategoryId, ItemName, ItemDescription, Price, Gst, IsActive, CreatedDate)
    VALUES (@ItemId, @ItemCategoryId, @ItemName, @ItemDescription, @Price, @Gst, @ItemIsActive, @ItemCreatedDate);
END;
 
 
EXEC InsertIntoTable

    @CategoryId = 3, @CategoryName = 'Snacks',  @CategoryDescription = 'Quick and light food', @CategoryIsActive = 0, @CategoryCreatedDate = '2025-06-02',
   
    @CouponId = 205, @CouponText = 'WELCOME50', @DiscountPercentage = 50.00, @ExpiryDate = '2025-12-30',

    @ItemId = 105, @ItemCategoryId = 3,  @ItemName = ' Tea', @ItemDescription =  'tea', @Price = 20.00, @Gst = 5.00,  @ItemIsActive = 1, @ItemCreatedDate = '2025-06-02';





-- CREATE FUNCTION


CREATE FUNCTION fn_totaLAmt (@price decimal(10,2), @quantity int, @gst int)
RETURNS DECIMAL(10,2) 
AS
BEGIN
   DECLARE @totalAmt decimal(10,2)

    SELECT @totalAmt = (@price * @quantity)  
    RETURN @totalAmt + (@totalAmt * @gst)/100
END



-- CREATE PROCEDURE TO INSERT DATA INTO 2 TABLES

ALTER PROCEDURE Insertintoorderandorderdetails
  @itemid INT,
  @quantity INT,
  @coupon INT = NULL  
AS
BEGIN
  
    DECLARE @subTotal DECIMAL(10,2)
    DECLARE @price DECIMAL(10,2)
    DECLARE @gst DECIMAL(10,2)
	DECLARE @deliveryCharge INT
	DECLARE @discount DECIMAL(10,2) = 0
	DECLARE @total DECIMAL(10,2)
	DECLARE @ordered INT



    IF NOT EXISTS (SELECT 1 FROM ItemMaster WHERE ItemId = @itemid AND IsActive = 1)
    BEGIN
        PRINT 'Item is not Available'
        RETURN
    END



    IF NOT EXISTS (SELECT 1 FROM CategoryMaster C JOIN ItemMaster I ON C.CategoryId = I.CategoryId WHERE I.ItemId = @itemid AND C.IsActive = 1 )
    BEGIN
        PRINT 'Category is not Available'
        RETURN
    END

    SELECT @price = Price, @gst = Gst FROM ItemMaster WHERE ItemId = @itemid

    SELECT @subTotal = dbo.fn_totaLAmt(@price, @quantity, @gst)


  
    IF (@subTotal > 1000)
        SET @deliveryCharge = 0
    ELSE IF (@subTotal BETWEEN 500 AND 1000)
        SET @deliveryCharge = 50
    ELSE
        SET @deliveryCharge = 80

   
  

    IF (@coupon IS NOT NULL)
    BEGIN
        IF EXISTS (SELECT 1 FROM CoupenMaster WHERE CouponedId = @coupon AND ExpiryDate >= GETDATE())
        BEGIN
            SELECT @discount = @subTotal * DiscountPercentage / 100 FROM CoupenMaster WHERE CouponedId = @coupon
        END
        ELSE
        BEGIN
            PRINT 'Coupon is not Valid'
            RETURN
        END
    END





    SET @total = (@subTotal - @discount) + @deliveryCharge




    INSERT INTO OrderMaster (Deliverycharge, CoupenAmount, SubTotal, Total, OrderedDate)
    VALUES (@deliveryCharge, @discount, @subTotal, @total, GETDATE())

    


    SET @ordered = SCOPE_IDENTITY()


    INSERT INTO OrderDetails (Ordered, ItemId, Quantity, Total)
    VALUES (@ordered, @itemid, @quantity, @total)
END




EXEC Insertintoorderandorderdetails @itemid = 102, @quantity = 2 , @coupon = 202;
	 
EXEC sp_msforeachtable 'select * from ?'
