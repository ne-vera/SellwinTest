USE MASTER;
GO

CREATE DATABASE SELLWIN_TEST;
GO

USE SELLWIN_TEST;
GO

CREATE TABLE DiscountPercent
(
	ID INT IDENTITY(1,1) CONSTRAINT PK_DiscountPercentID PRIMARY KEY,
	Name NVARCHAR(MAX) NOT NULL,
	Percentage FLOAT NOT NULL
);

CREATE TABLE Cards
(
	Series NCHAR(5),
	Number INT IDENTITY(10000, 1),
	IssueDate SMALLDATETIME NOT NULL,
	ExpirationDate SMALLDATETIME NOT NULL,
	LastUseDate SMALLDATETIME,
	PurchaseAmount MONEY DEFAULT 0 NOT NULL,
	Status NVARCHAR(MAX) CHECK (Status IN ('не активирована', 'активирована', 'просрочена')),
	DiscountPercentID INT CONSTRAINT FK_Cards_DiscountPercentID REFERENCES DiscountPercent(ID),
	CONSTRAINT PK_Cards PRIMARY KEY (Series, Number)
);

CREATE TABLE Orders
(
	Number INT IDENTITY(1,1) CONSTRAINT PK_OrdersNumber PRIMARY KEY,
	CardSeries NCHAR(5),
	CardNumber INT,
	Date SMALLDATETIME NOT NULL,
	Amount MONEY NOT NULL,
	DiscountPercentID INT CONSTRAINT FK_Orders_DiscountPercentID REFERENCES DiscountPercent(ID),
	DiscountAmount MONEY NOT NULL,
	CONSTRAINT FK_Cards FOREIGN KEY (CardSeries, CardNumber) REFERENCES Cards(Series, Number)
);

CREATE TABLE Products
(
	ID INT IDENTITY(1,1) CONSTRAINT PK_ProductsNumber PRIMARY KEY,
	OrderNumber INT CONSTRAINT FK_OrdersNumber REFERENCES Orders(Number),
	Name NVARCHAR(MAX) NOT NULL,
	Price MONEY NOT NULL,
	PriceWithDiscount MONEY NOT NULL
);

INSERT INTO DiscountPercent VALUES ('Социальная', 5),
									('День рождение', 3.8),
									('Черная пятница', 22.2);

INSERT INTO Cards(Series, IssueDate, ExpirationDate, Status, DiscountPercentID)
				VALUES ('11111', '20200508 12:35:29',  '20240508 12:35:29', 'активирована', 1),
						('11111', '20220430 00:00:00',  '20220530 00:00:00', 'не активирована', 2),
						('11112', '20221111 00:00:00',  '20221112 00:00:00', 'просрочена', 3);

INSERT INTO Orders VALUES ('11111', 10002, '20200509 12:40:29', 20, 1, 1) 

INSERT INTO Products VALUES (1, 'Товар 1', 20, 19)

--хранимые процедуры

-- получение список карт с полями: серия, номер, дата выпуска, дата окончания активности, статус, функцией поиска по полям;
GO

CREATE PROCEDURE GetCardList
	@series NCHAR(5) = NULL,
	@number INT = NULL,
	@issue_date DATE = NULL, 
	@expiration_date DATE = NULL,
	@status NVARCHAR(MAX) = NULL
AS
BEGIN
	BEGIN TRY
	 SELECT Series, Number, IssueDate, ExpirationDate, Status
		FROM Cards
		WHERE (@series IS NULL OR Series LIKE '%' + @series + '%')
			AND (@number IS NULL OR Number = @number)
			AND (@issue_date IS NULL OR CAST(IssueDate AS DATE) = @issue_date)
			AND (@expiration_date IS NULL OR CAST(ExpirationDate AS DATE) = @expiration_date)
			AND (@status IS NULL OR Status = @status)
	END TRY
	BEGIN CATCH
		PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC GetCardList @series='11111';
EXEC GetCardList @issue_date='20200508';

-- просмотра профиля карты с историей покупок по ней;
GO

CREATE PROCEDURE GetCardProfile
	@number INT,
	@series NCHAR(5)
AS
BEGIN
	BEGIN TRY
		SELECT Cards.Series, Cards.Number, Cards.IssueDate, Cards.ExpirationDate, Cards.PurchaseAmount, Cards.Status, Cards.DiscountPercentID, Orders.Number
		FROM Cards INNER JOIN Orders 
		ON Cards.Series = Orders.CardSeries AND
		Cards.Number = Orders.CardNumber
		WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
	END TRY
	BEGIN CATCH
	PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC GetCardProfile @series = '11111', @number = 10002;

-- активация/деактивация карты;
GO

CREATE PROCEDURE ActivateCard
	@number INT,
	@series NCHAR(5)
AS
BEGIN
	BEGIN TRY
		UPDATE Cards SET Status = 'активирована'
		WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
	END TRY
	BEGIN CATCH
	PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC ActivateCard @series = '11111', @number = 10003;
SELECT * FROM Cards WHERE Series = '11111' AND Number = 10003;

GO

CREATE PROCEDURE DeactivateCard
	@number INT,
	@series NCHAR(5)
AS
BEGIN
	BEGIN TRY
		UPDATE Cards SET Status = 'не активирована'
		WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
	END TRY
	BEGIN CATCH
		PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC DeactivateCard @series = '11111', @number = 10003;
SELECT * FROM Cards WHERE Series = '11111' AND Number = 10003;

-- генератор карт, с указанием серии и количества генерируемых карт, а срока активности «с-по».
GO

CREATE PROCEDURE GenerateCards
	@series NCHAR(5),
	@discoutID INT,
	@issueDate SMALLDATETIME,
	@expirationDate SMALLDATETIME,
	@num INT
AS
BEGIN
	BEGIN TRY
		WHILE @num > 0
			BEGIN
				INSERT INTO Cards(Series, IssueDate, ExpirationDate, Status, DiscountPercentID)
				VALUES (@series, @issueDate, @expirationDate, 'не активирована', @discoutID);
				 SET @num = @num - 1
			END
	END TRY
	BEGIN CATCH
		PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC GenerateCards @series='22222',@discoutID=1, @issueDate = '20230303 00:00', @expirationDate = '20250303 00:00', @num = 5;
SELECT * FROM Cards;

-- после истечения срока активности карты, у карты проставляется статус "просрочена";
GO

CREATE PROCEDURE SetCardExpired
AS
BEGIN
	BEGIN TRY
		UPDATE Cards SET Status = 'просрочена'
		WHERE ExpirationDate < GETDATE() AND Status <> 'просрочена'
	END TRY
	BEGIN CATCH
		PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC GenerateCards @series='33333',@discoutID=1, @issueDate = '20200303 00:00', @expirationDate = '20220303 00:00', @num = 1;
EXEC SetCardExpired;
SELECT * FROM Cards;

-- записи информации по заказам и товарам для определенной карты. 
GO

CREATE PROCEDURE InputToCard
	@number INT,
	@series NCHAR(5)
AS
BEGIN
	BEGIN TRY
			UPDATE Cards SET LastUseDate = 
				(SElECT TOP(1) Orders.Date from Orders 
					WHERE (Orders.CardSeries LIKE '%' + @series + '%')
							AND (Orders.CardNumber = @number)
					ORDER BY Orders.Date DESC)
			WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
			UPDATE Cards SET PurchaseAmount = 
			(SELECT SUM(Orders.Amount) FROM ORDERS 
				WHERE (Orders.CardSeries LIKE '%' + @series + '%')
						AND (Orders.CardNumber = @number))
			WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
	END TRY
	BEGIN CATCH
			PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
			PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
			PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

EXEC InputToCard @series = '11111', @number = 10002;
SELECT * FROM Cards;

-- удаление карты (сперва в корзину с возможностью восстановления);
GO
ALTER TABLE Cards ADD IsDeleted BIT NOT NULL DEFAULT 0;

GO

CREATE PROCEDURE DeleteCard
	@series NCHAR(5),
	@number INT
AS
BEGIN
	BEGIN TRY
		UPDATE Cards Set IsDeleted = 1
		WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
	END TRY
	BEGIN CATCH
		PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;

GO
CREATE PROCEDURE RestoreCard
	@series NCHAR(5),
	@number INT
AS
BEGIN
	BEGIN TRY
		UPDATE Cards Set IsDeleted = 0
		WHERE (Cards.Series LIKE '%' + @series + '%')
			AND (Cards.Number = @number)
	END TRY
	BEGIN CATCH
		PRINT 'Код ошибки:  ' + CAST(ERROR_NUMBER() as varchar)
		PRINT 'Уровень серьезности: ' + CAST(ERROR_SEVERITY() as varchar)
		PRINT 'Текст сообщения:   ' + CAST(ERROR_MESSAGE() as varchar)
	END CATCH
END;