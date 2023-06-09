USE [master]
GO
/****** Object:  Database [u_pczech]    Script Date: 26.05.2023 20:48:41 ******/
CREATE DATABASE [u_pczech]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'u_pczech', FILENAME = N'/var/opt/mssql/data/u_pczech.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'u_pczech_log', FILENAME = N'/var/opt/mssql/data/u_pczech_log.ldf' , SIZE = 66048KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [u_pczech] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [u_pczech].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [u_pczech] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [u_pczech] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [u_pczech] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [u_pczech] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [u_pczech] SET ARITHABORT OFF 
GO
ALTER DATABASE [u_pczech] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [u_pczech] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [u_pczech] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [u_pczech] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [u_pczech] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [u_pczech] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [u_pczech] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [u_pczech] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [u_pczech] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [u_pczech] SET  ENABLE_BROKER 
GO
ALTER DATABASE [u_pczech] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [u_pczech] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [u_pczech] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [u_pczech] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [u_pczech] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [u_pczech] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [u_pczech] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [u_pczech] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [u_pczech] SET  MULTI_USER 
GO
ALTER DATABASE [u_pczech] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [u_pczech] SET DB_CHAINING OFF 
GO
ALTER DATABASE [u_pczech] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [u_pczech] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [u_pczech] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [u_pczech] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [u_pczech] SET QUERY_STORE = OFF
GO
USE [u_pczech]
GO
/****** Object:  DatabaseRole [worker]    Script Date: 26.05.2023 20:48:41 ******/
CREATE ROLE [worker]
GO
/****** Object:  DatabaseRole [manager]    Script Date: 26.05.2023 20:48:41 ******/
CREATE ROLE [manager]
GO
/****** Object:  UserDefinedFunction [dbo].[GetClientOrderCount]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetClientOrderCount] (@ClientID int)
RETURNS int
AS
BEGIN
	DECLARE @OrderCount INT
	SET @OrderCount = (SELECT COUNT(OrderID) FROM Orders WHERE ClientID = @ClientID)
	RETURN @OrderCount
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetClientOrderCountGreaterThan]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetClientOrderCountGreaterThan] (@ClientID int, @K1 int)
RETURNS int
AS
BEGIN
	DECLARE @OrderCount INT
	SET @OrderCount = (SELECT COUNT(OrderID) FROM Orders WHERE ClientID = @ClientID AND dbo.GetOrderValue(OrderID)>@K1)
	RETURN @OrderCount
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetClientOrderValue]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetClientOrderValue](@ClientID int)
RETURNS FLOAT
AS
BEGIN
	DECLARE @Value float
	SET @Value = 
	(SELECT SUM(VL) FROM (SELECT dbo.GetOrderValue(OrderID) AS VL FROM Orders WHERE ClientID = @ClientID) AS VALS)
	IF (@Value IS NULL)
		BEGIN;
			RETURN 0
		END
	RETURN @Value
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetDiscountRate]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetDiscountRate] (@DiscountID int)
RETURNS int
AS
BEGIN
	DECLARE @Type bit
	SELECT @Type = Type FROM Discounts WHERE @DiscountID = DiscountID
	DECLARE @DiscountParamsID int
	SELECT @DiscountParamsID = DiscountParamsID FROM Discounts WHERE @DiscountID = DiscountID
	DECLARE @DiscountRate int
	IF (@Type = 0)
		BEGIN
			SELECT @DiscountRate = DiscountR1 FROM DiscountParams WHERE @DiscountParamsID = DiscountParamsID
		END
	IF (@Type = 1)
		BEGIN
			SELECT @DiscountRate = DiscountR2 FROM DiscountParams WHERE @DiscountParamsID = DiscountParamsID
		END
	RETURN @DiscountRate
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetOrderValue]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetOrderValue](@OrderID int)
RETURNS FLOAT
AS
BEGIN
	DECLARE @Value float
	SET @Value = 
	(SELECT SUM(ProdValues) FROM (SELECT Quantity*UnitPrice*(100-isnull(DiscountRate, 0))/100 AS ProdValues FROM OrderDetails 
	INNER JOIN Orders ON Orders.OrderID = OrderDetails.OrderID 
	INNER JOIN Menu ON Menu.ProductID = OrderDetails.ProductID 
	WHERE Orders.OrderID = @OrderID AND Menu.DateFrom<=Orders.OrderDate AND (Menu.DateTo>Orders.OrderDate OR Menu.DateTo IS NULL)) AS VALS)
	IF (@Value IS NULL)
		BEGIN;
			RETURN 0
		END
	RETURN @Value
END
GO
/****** Object:  Table [dbo].[Tables]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tables](
	[TableID] [int] NOT NULL,
	[Capacity] [int] NOT NULL,
	[Available] [bit] NOT NULL,
 CONSTRAINT [PK_Tables] PRIMARY KEY CLUSTERED 
(
	[TableID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[FreeTables]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[FreeTables]
AS
SELECT TableID, Capacity
FROM     dbo.Tables
WHERE  (Available = 1)
GO
/****** Object:  Table [dbo].[OrderDetails]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderDetails](
	[OrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
 CONSTRAINT [PK_OrderDetails_1] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ProductTimesSoldAllTime]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ProductTimesSoldAllTime]
AS
SELECT ProductID, SUM(Quantity) AS TimesSold
FROM     dbo.OrderDetails
GROUP BY ProductID
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders](
	[OrderID] [int] NOT NULL,
	[ClientID] [int] NOT NULL,
	[OrderDate] [date] NOT NULL,
	[FinalizedDate] [date] NULL,
	[ToBeIssuedDate] [date] NULL,
	[Paid] [bit] NULL,
	[DiscountRate] [int] NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ProductTimesSoldLastMonth]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ProductTimesSoldLastMonth]
AS
SELECT dbo.OrderDetails.ProductID, SUM(dbo.OrderDetails.Quantity) AS TimesSold
FROM     dbo.OrderDetails INNER JOIN
                  dbo.Orders ON dbo.Orders.OrderID = dbo.OrderDetails.OrderID
WHERE  (DATEDIFF(day, dbo.Orders.OrderDate, GETDATE()) < 31)
GROUP BY dbo.OrderDetails.ProductID
GO
/****** Object:  Table [dbo].[Products]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Products](
	[ProductID] [int] NOT NULL,
	[ProductName] [varchar](50) NOT NULL,
	[CategoryID] [int] NOT NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Menu]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Menu](
	[ProductID] [int] NOT NULL,
	[DateFrom] [datetime] NOT NULL,
	[DateTo] [datetime] NULL,
	[UnitPrice] [money] NOT NULL,
	[MenuID] [int] NOT NULL,
 CONSTRAINT [PK_Menu_1] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC,
	[MenuID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UniqueMenuPair] UNIQUE NONCLUSTERED 
(
	[ProductID] ASC,
	[MenuID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ProductsToDelete]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ProductsToDelete]
AS
SELECT dbo.Products.ProductName, ISNULL(P.TimesSold, 0) AS TimesSold
FROM     dbo.Menu INNER JOIN
                  dbo.Products ON dbo.Products.ProductID = dbo.Menu.ProductID LEFT OUTER JOIN
                  dbo.ProductTimesSoldLastMonth AS P ON P.ProductID = dbo.Menu.ProductID
WHERE  (dbo.Menu.DateTo IS NULL) AND (DATEDIFF(day, dbo.Menu.DateFrom, GETDATE()) > 14)
GO
/****** Object:  Table [dbo].[DiscountParams]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountParams](
	[OrderCountZ1] [int] NOT NULL,
	[OrderPriceK1] [int] NOT NULL,
	[DiscountR1] [int] NOT NULL,
	[SumK2] [int] NOT NULL,
	[DiscountR2] [int] NOT NULL,
	[DurationD1] [int] NOT NULL,
	[DiscountParamsID] [int] NOT NULL,
	[DateFrom] [datetime] NOT NULL,
	[DateTo] [datetime] NULL,
 CONSTRAINT [PK_DiscountParams] PRIMARY KEY CLUSTERED 
(
	[DiscountParamsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Discounts]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Discounts](
	[DiscountID] [int] NOT NULL,
	[ClientID] [int] NOT NULL,
	[Type] [bit] NOT NULL,
	[DiscountParamsID] [int] NOT NULL,
	[UsedDate] [date] NULL,
 CONSTRAINT [PK_Discounts] PRIMARY KEY CLUSTERED 
(
	[DiscountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ActiveDiscounts]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ActiveDiscounts]
AS
SELECT dbo.Discounts.ClientID, dbo.Discounts.DiscountID
FROM     dbo.Discounts INNER JOIN
                  dbo.DiscountParams ON dbo.Discounts.DiscountParamsID = dbo.DiscountParams.DiscountParamsID
WHERE  (dbo.Discounts.Type = 0) OR
                  (dbo.Discounts.Type = 1) AND (DATEDIFF(day, dbo.Discounts.UsedDate, GETDATE()) < dbo.DiscountParams.DurationD1)
GO
/****** Object:  View [dbo].[CurrMenuStats]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CurrMenuStats]
AS
SELECT TOP (100) PERCENT dbo.Products.ProductName, DATEDIFF(day, dbo.Menu.DateFrom, GETDATE()) AS DaysInMenu, SUM(dbo.OrderDetails.Quantity) AS TimesSold
FROM     dbo.OrderDetails INNER JOIN
                  dbo.Menu ON dbo.Menu.ProductID = dbo.OrderDetails.ProductID INNER JOIN
                  dbo.Products ON dbo.Products.ProductID = dbo.Menu.ProductID
WHERE  (dbo.Menu.DateTo IS NULL)
GROUP BY dbo.Products.ProductName, dbo.Menu.DateFrom
ORDER BY TimesSold DESC
GO
/****** Object:  View [dbo].[UnpaidOrders]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UnpaidOrders]
AS
SELECT OrderID, ClientID, OrderDate
FROM     dbo.Orders
WHERE  (Paid = 0)
GO
/****** Object:  Table [dbo].[Clients]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clients](
	[ClientID] [int] NOT NULL,
	[Phone] [varchar](50) NULL,
	[Email] [varchar](50) NULL,
 CONSTRAINT [PK_Clients] PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UniqueEmail] UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UniquePhone] UNIQUE NONCLUSTERED 
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[IndividualClient]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IndividualClient](
	[ClientID] [int] NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_IndividualClient] PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[IndClientStats]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[IndClientStats]
AS
SELECT dbo.Clients.ClientID, dbo.IndividualClient.FirstName, dbo.IndividualClient.LastName, dbo.Clients.Phone, dbo.Clients.Email, dbo.GetClientOrderCount(dbo.Clients.ClientID) AS NumOfOrders, dbo.GetClientOrderValue(dbo.Clients.ClientID) 
                  AS SumOfOrders
FROM     dbo.Clients INNER JOIN
                  dbo.IndividualClient ON dbo.Clients.ClientID = dbo.IndividualClient.ClientID
GO
/****** Object:  Table [dbo].[Cities]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cities](
	[CityID] [int] NOT NULL,
	[CityName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Cities] PRIMARY KEY CLUSTERED 
(
	[CityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Countries]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Countries](
	[CountryID] [int] NOT NULL,
	[CountryName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Countries] PRIMARY KEY CLUSTERED 
(
	[CountryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BusinessClient]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BusinessClient](
	[ClientID] [int] NOT NULL,
	[CompanyName] [varchar](50) NOT NULL,
	[NIP] [varchar](50) NOT NULL,
	[Street] [varchar](50) NOT NULL,
	[CityID] [int] NOT NULL,
	[PostalCode] [varchar](50) NOT NULL,
	[CountryID] [int] NOT NULL,
 CONSTRAINT [PK_BusinessClient] PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UniqueNIP] UNIQUE NONCLUSTERED 
(
	[NIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[BusClientStats]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[BusClientStats]
AS
SELECT dbo.Clients.ClientID, dbo.BusinessClient.CompanyName, dbo.BusinessClient.NIP, dbo.Clients.Phone, dbo.Clients.Email, dbo.BusinessClient.Street, dbo.Cities.CityName, dbo.BusinessClient.PostalCode, dbo.Countries.CountryName, 
                  dbo.GetClientOrderCount(dbo.Clients.ClientID) AS NumOfOrders, dbo.GetClientOrderValue(dbo.Clients.ClientID) AS SumOfOrders
FROM     dbo.Clients INNER JOIN
                  dbo.BusinessClient ON dbo.Clients.ClientID = dbo.BusinessClient.ClientID INNER JOIN
                  dbo.Cities ON dbo.BusinessClient.CityID = dbo.Cities.CityID INNER JOIN
                  dbo.Countries ON dbo.Countries.CountryID = dbo.BusinessClient.CountryID
GO
/****** Object:  View [dbo].[ProdMonthlyReport]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ProdMonthlyReport]
AS
SELECT dbo.Products.ProductName, YEAR(O.OrderDate) AS 'Year', DATENAME(month, O.OrderDate) AS 'Month', ISNULL(SUM(OD.Quantity), 0) AS TimesSold
FROM     dbo.Products LEFT OUTER JOIN
                  dbo.OrderDetails AS OD ON OD.ProductID = dbo.Products.ProductID LEFT OUTER JOIN
                  dbo.Orders AS O ON O.OrderID = OD.OrderID
GROUP BY dbo.Products.ProductName, YEAR(O.OrderDate), DATENAME(month, O.OrderDate)
GO
/****** Object:  View [dbo].[ProdWeeklyReport]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ProdWeeklyReport]
AS
SELECT dbo.Products.ProductName, YEAR(O.OrderDate) AS 'Year', DATENAME(week, O.OrderDate) AS 'Week', ISNULL(SUM(OD.Quantity), 0) AS TimesSold
FROM     dbo.Products LEFT OUTER JOIN
                  dbo.OrderDetails AS OD ON OD.ProductID = dbo.Products.ProductID LEFT OUTER JOIN
                  dbo.Orders AS O ON O.OrderID = OD.OrderID
GROUP BY dbo.Products.ProductName, YEAR(O.OrderDate), DATENAME(week, O.OrderDate)
GO
/****** Object:  View [dbo].[OrdersPerMonth]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[OrdersPerMonth]
AS
SELECT DATENAME(month, OrderDate) AS Month, ISNULL(COUNT(OrderID), 0) AS NumOfOrders
FROM     dbo.Orders
GROUP BY DATENAME(month, OrderDate)
GO
/****** Object:  View [dbo].[OrdersPerWeekDay]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[OrdersPerWeekDay]
AS
SELECT DATENAME(weekday, OrderDate) AS WeekDay, ISNULL(COUNT(OrderID), 0) AS NumOfOrders
FROM     dbo.Orders
GROUP BY DATENAME(weekday, OrderDate)
GO
/****** Object:  View [dbo].[LostOnDiscMonthly]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LostOnDiscMonthly]
AS
SELECT YEAR(OrderDate) AS Year, DATENAME(month, OrderDate) AS Month, SUM((dbo.GetOrderValue(OrderID) * ISNULL(DiscountRate, 0)) / (100 - ISNULL(DiscountRate, 0))) AS LostMoney
FROM     dbo.Orders
GROUP BY YEAR(OrderDate), DATENAME(month, OrderDate)
GO
/****** Object:  View [dbo].[LostOnDiscWeekly]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LostOnDiscWeekly]
AS
SELECT YEAR(OrderDate) AS Year, DATENAME(week, OrderDate) AS Week, SUM((dbo.GetOrderValue(OrderID) * ISNULL(DiscountRate, 0)) / (100 - ISNULL(DiscountRate, 0))) AS LostMoney
FROM     dbo.Orders
GROUP BY YEAR(OrderDate), DATENAME(week, OrderDate)
GO
/****** Object:  Table [dbo].[Reservations]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reservations](
	[ReservationID] [int] NOT NULL,
	[TableID] [int] NULL,
	[NumOfSeats] [int] NOT NULL,
	[DateFrom] [datetime] NOT NULL,
	[DateTo] [datetime] NOT NULL,
	[Accepted] [bit] NOT NULL,
	[Cancelled] [bit] NULL,
 CONSTRAINT [PK_ReservationsBusiness] PRIMARY KEY CLUSTERED 
(
	[ReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ReservStatsWeekly]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ReservStatsWeekly]
AS
SELECT YEAR(DateFrom) AS Year, DATENAME(week, DateFrom) AS Week, COUNT(ReservationID) AS NumOfRes, SUM(NumOfSeats) AS SumOfSeats
FROM     dbo.Reservations
WHERE  (Accepted = 1)
GROUP BY YEAR(DateFrom), DATENAME(week, DateFrom)
GO
/****** Object:  View [dbo].[ReservStatsMonthly]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ReservStatsMonthly]
AS
SELECT YEAR(DateFrom) AS Year, DATENAME(month, DateFrom) AS Month, COUNT(ReservationID) AS NumOfRes, SUM(NumOfSeats) AS SumOfSeats
FROM     dbo.Reservations
WHERE  (Accepted = 1)
GROUP BY YEAR(DateFrom), DATENAME(month, DateFrom)
GO
/****** Object:  View [dbo].[CurrBestDiscount]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CurrBestDiscount]
AS
SELECT dbo.IndividualClient.ClientID, ISNULL(MAX(dbo.GetDiscountRate(dbo.ActiveDiscounts.DiscountID)), 0) AS BestDiscountRate
FROM     dbo.ActiveDiscounts RIGHT OUTER JOIN
                  dbo.IndividualClient ON dbo.IndividualClient.ClientID = dbo.ActiveDiscounts.ClientID
GROUP BY dbo.IndividualClient.ClientID
GO
/****** Object:  View [dbo].[AssignedDiscMonthly]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AssignedDiscMonthly]
AS
SELECT YEAR(UsedDate) AS Year, DATENAME(month, UsedDate) AS Month, Type, ISNULL(COUNT(DiscountID), 0) AS NumOfDiscounts
FROM     dbo.Discounts
GROUP BY YEAR(UsedDate), DATENAME(month, UsedDate), Type
GO
/****** Object:  View [dbo].[AssignedDiscWeekly]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AssignedDiscWeekly]
AS
SELECT YEAR(UsedDate) AS Year, DATENAME(week, UsedDate) AS Week, Type, ISNULL(COUNT(DiscountID), 0) AS NumOfDiscounts
FROM     dbo.Discounts
GROUP BY YEAR(UsedDate), DATENAME(week, UsedDate), Type
GO
/****** Object:  View [dbo].[SeaFoodNextWeek]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[SeaFoodNextWeek]
AS
SELECT DATENAME(weekday, dbo.Orders.ToBeIssuedDate) AS WeekDay, P.ProductName, SUM(OD.Quantity) AS Quantity
FROM     dbo.Orders INNER JOIN
                  dbo.OrderDetails AS OD ON OD.OrderID = dbo.Orders.OrderID INNER JOIN
                  dbo.Products AS P ON P.ProductID = OD.ProductID
WHERE  (dbo.Orders.ToBeIssuedDate > GETDATE()) AND (P.CategoryID = 3)
GROUP BY DATENAME(weekday, dbo.Orders.ToBeIssuedDate), P.ProductName
GO
/****** Object:  View [dbo].[MenuList]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[MenuList]
AS
SELECT dbo.Products.ProductName, dbo.Menu.UnitPrice AS Price
FROM     dbo.Products INNER JOIN
                  dbo.Menu ON dbo.Menu.ProductID = dbo.Products.ProductID
WHERE  (dbo.Menu.DateTo IS NULL)
GO
/****** Object:  Table [dbo].[Categories]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Categories](
	[CategoryID] [int] NOT NULL,
	[CategoryName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ProductInfo]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ProductInfo]
AS
SELECT dbo.Products.ProductName, dbo.Categories.CategoryName
FROM     dbo.Products INNER JOIN
                  dbo.Categories ON dbo.Categories.CategoryID = dbo.Products.CategoryID
GO
/****** Object:  View [dbo].[ReservToAccept]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ReservToAccept]
AS
SELECT ReservationID
FROM     dbo.Reservations
WHERE  (Accepted = 0)
GO
/****** Object:  View [dbo].[CurrDiscParams]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CurrDiscParams]
AS
SELECT OrderCountZ1, OrderPriceK1, DiscountR1, SumK2, DiscountR2, DurationD1
FROM     dbo.DiscountParams
WHERE  (DateTo IS NULL)
GO
/****** Object:  View [dbo].[ReservationInfo]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ReservationInfo]
AS
SELECT ReservationID, NumOfSeats, DATEDIFF(hour, DateFrom, DateTo) AS Duration
FROM     dbo.Reservations
WHERE  (Accepted = 1)
GO
/****** Object:  View [dbo].[OrdersInfo]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[OrdersInfo]
AS
SELECT A.OrderID, dbo.Orders.ClientID, dbo.Orders.OrderDate, SUM(A.Sum) AS TotalWorth
FROM     (SELECT dbo.OrderDetails.OrderID, dbo.OrderDetails.ProductID, dbo.OrderDetails.Quantity, M.UnitPrice, dbo.OrderDetails.Quantity * M.UnitPrice AS Sum
                  FROM      dbo.OrderDetails INNER JOIN
                                        (SELECT ProductID, UnitPrice, DateTo, DateFrom
                                         FROM      dbo.Menu) AS M ON M.ProductID = dbo.OrderDetails.ProductID) AS A INNER JOIN
                  dbo.Orders ON A.OrderID = dbo.Orders.OrderID
GROUP BY A.OrderID, dbo.Orders.ClientID, dbo.Orders.OrderDate
GO
/****** Object:  UserDefinedFunction [dbo].[STR_SPLIT]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[STR_SPLIT]
(
  @List      nvarchar(max),
  @Delimiter nchar(1)
)
RETURNS table WITH SCHEMABINDING
AS
  RETURN
  (
    SELECT value, ordinal = [key]
    FROM OPENJSON(N'["' + REPLACE(@List, @Delimiter, N'","') + N'"]') AS x
  );
GO
/****** Object:  Table [dbo].[ReservationsBusiness]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReservationsBusiness](
	[ReservationID] [int] NOT NULL,
	[ClientID] [int] NOT NULL,
	[GuestList] [varchar](3000) NULL,
 CONSTRAINT [PK_ReservationsBusiness_1] PRIMARY KEY CLUSTERED 
(
	[ReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReservationsIndividual]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReservationsIndividual](
	[ReservationID] [int] NOT NULL,
	[OrderID] [int] NOT NULL,
	[ClientID] [int] NOT NULL,
 CONSTRAINT [PK_ReservationsIndividual] PRIMARY KEY CLUSTERED 
(
	[ReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReservationsParams]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReservationsParams](
	[WZ] [int] NOT NULL,
	[WK] [int] NOT NULL,
	[ReservationsParamsID] [int] NOT NULL,
 CONSTRAINT [PK_ReservationsParams] PRIMARY KEY CLUSTERED 
(
	[ReservationsParamsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CompanyNameIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE NONCLUSTERED INDEX [CompanyNameIndex] ON [dbo].[BusinessClient]
(
	[CompanyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CategoryNameIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE UNIQUE NONCLUSTERED INDEX [CategoryNameIndex] ON [dbo].[Categories]
(
	[CategoryName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CityNameIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE UNIQUE NONCLUSTERED INDEX [CityNameIndex] ON [dbo].[Cities]
(
	[CityName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [EmailIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE UNIQUE NONCLUSTERED INDEX [EmailIndex] ON [dbo].[Clients]
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [PhoneIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE UNIQUE NONCLUSTERED INDEX [PhoneIndex] ON [dbo].[Clients]
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ClientNameIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE NONCLUSTERED INDEX [ClientNameIndex] ON [dbo].[IndividualClient]
(
	[FirstName] ASC,
	[LastName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [ProductNameIndex]    Script Date: 26.05.2023 20:48:41 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ProductNameIndex] ON [dbo].[Products]
(
	[ProductName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BusinessClient]  WITH CHECK ADD  CONSTRAINT [FK_BusinessClient_Cities] FOREIGN KEY([CityID])
REFERENCES [dbo].[Cities] ([CityID])
GO
ALTER TABLE [dbo].[BusinessClient] CHECK CONSTRAINT [FK_BusinessClient_Cities]
GO
ALTER TABLE [dbo].[BusinessClient]  WITH CHECK ADD  CONSTRAINT [FK_BusinessClient_Clients] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Clients] ([ClientID])
GO
ALTER TABLE [dbo].[BusinessClient] CHECK CONSTRAINT [FK_BusinessClient_Clients]
GO
ALTER TABLE [dbo].[BusinessClient]  WITH CHECK ADD  CONSTRAINT [FK_BusinessClient_Countries] FOREIGN KEY([CountryID])
REFERENCES [dbo].[Countries] ([CountryID])
GO
ALTER TABLE [dbo].[BusinessClient] CHECK CONSTRAINT [FK_BusinessClient_Countries]
GO
ALTER TABLE [dbo].[Discounts]  WITH CHECK ADD  CONSTRAINT [FK_Discounts_DiscountParams] FOREIGN KEY([DiscountParamsID])
REFERENCES [dbo].[DiscountParams] ([DiscountParamsID])
GO
ALTER TABLE [dbo].[Discounts] CHECK CONSTRAINT [FK_Discounts_DiscountParams]
GO
ALTER TABLE [dbo].[Discounts]  WITH CHECK ADD  CONSTRAINT [FK_Discounts_IndividualClient] FOREIGN KEY([ClientID])
REFERENCES [dbo].[IndividualClient] ([ClientID])
GO
ALTER TABLE [dbo].[Discounts] CHECK CONSTRAINT [FK_Discounts_IndividualClient]
GO
ALTER TABLE [dbo].[IndividualClient]  WITH CHECK ADD  CONSTRAINT [FK_IndividualClient_Clients] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Clients] ([ClientID])
GO
ALTER TABLE [dbo].[IndividualClient] CHECK CONSTRAINT [FK_IndividualClient_Clients]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [FK_Menu_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ProductID])
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [FK_Menu_Products]
GO
ALTER TABLE [dbo].[OrderDetails]  WITH CHECK ADD  CONSTRAINT [FK_OrderDetails_Orders] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
GO
ALTER TABLE [dbo].[OrderDetails] CHECK CONSTRAINT [FK_OrderDetails_Orders]
GO
ALTER TABLE [dbo].[OrderDetails]  WITH CHECK ADD  CONSTRAINT [FK_OrderDetails_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ProductID])
GO
ALTER TABLE [dbo].[OrderDetails] CHECK CONSTRAINT [FK_OrderDetails_Products]
GO
ALTER TABLE [dbo].[Products]  WITH CHECK ADD  CONSTRAINT [FK_Products_Categories] FOREIGN KEY([CategoryID])
REFERENCES [dbo].[Categories] ([CategoryID])
GO
ALTER TABLE [dbo].[Products] CHECK CONSTRAINT [FK_Products_Categories]
GO
ALTER TABLE [dbo].[Reservations]  WITH CHECK ADD  CONSTRAINT [FK_Reservations_Tables] FOREIGN KEY([TableID])
REFERENCES [dbo].[Tables] ([TableID])
GO
ALTER TABLE [dbo].[Reservations] CHECK CONSTRAINT [FK_Reservations_Tables]
GO
ALTER TABLE [dbo].[ReservationsBusiness]  WITH CHECK ADD  CONSTRAINT [FK_ReservationsBusiness_BusinessClient] FOREIGN KEY([ClientID])
REFERENCES [dbo].[BusinessClient] ([ClientID])
GO
ALTER TABLE [dbo].[ReservationsBusiness] CHECK CONSTRAINT [FK_ReservationsBusiness_BusinessClient]
GO
ALTER TABLE [dbo].[ReservationsBusiness]  WITH CHECK ADD  CONSTRAINT [FK_ReservationsBusiness_Reservations] FOREIGN KEY([ReservationID])
REFERENCES [dbo].[Reservations] ([ReservationID])
GO
ALTER TABLE [dbo].[ReservationsBusiness] CHECK CONSTRAINT [FK_ReservationsBusiness_Reservations]
GO
ALTER TABLE [dbo].[ReservationsIndividual]  WITH CHECK ADD  CONSTRAINT [FK_ReservationsIndividual_IndividualClient] FOREIGN KEY([ClientID])
REFERENCES [dbo].[IndividualClient] ([ClientID])
GO
ALTER TABLE [dbo].[ReservationsIndividual] CHECK CONSTRAINT [FK_ReservationsIndividual_IndividualClient]
GO
ALTER TABLE [dbo].[ReservationsIndividual]  WITH CHECK ADD  CONSTRAINT [FK_ReservationsIndividual_Reservations] FOREIGN KEY([ReservationID])
REFERENCES [dbo].[Reservations] ([ReservationID])
GO
ALTER TABLE [dbo].[ReservationsIndividual] CHECK CONSTRAINT [FK_ReservationsIndividual_Reservations]
GO
ALTER TABLE [dbo].[BusinessClient]  WITH CHECK ADD  CONSTRAINT [NIPConstr] CHECK  (([NIP] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[BusinessClient] CHECK CONSTRAINT [NIPConstr]
GO
ALTER TABLE [dbo].[BusinessClient]  WITH CHECK ADD  CONSTRAINT [PostalCodeConstr] CHECK  (([PostalCode] like '[0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[BusinessClient] CHECK CONSTRAINT [PostalCodeConstr]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [EmailConstr] CHECK  (([Email] like '%@%.%'))
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [EmailConstr]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [PhoneConstr] CHECK  (([Phone] like '+[0-9][0-9] [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [PhoneConstr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [D1Constr] CHECK  (([DurationD1]>=(0)))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [D1Constr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [DP_DatesConstr] CHECK  ((isnull([DateTo],'9999-12-31 23:59:59')>[DateFrom]))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [DP_DatesConstr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [K1Constr] CHECK  (([OrderPriceK1]>=(0)))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [K1Constr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [K2Constr] CHECK  (([SumK2]>=(0)))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [K2Constr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [R1Constr] CHECK  (([DiscountR1]>=(0) AND [DiscountR1]<=(100)))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [R1Constr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [R2Constr] CHECK  (([DiscountR2]>=(0) AND [DiscountR2]<=(100)))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [R2Constr]
GO
ALTER TABLE [dbo].[DiscountParams]  WITH CHECK ADD  CONSTRAINT [Z1Constr] CHECK  (([OrderCountZ1]>=(0)))
GO
ALTER TABLE [dbo].[DiscountParams] CHECK CONSTRAINT [Z1Constr]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [M_DatesConstr] CHECK  (([DateFrom]<isnull([DateTo],'9999-12-31 23:59:59')))
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [M_DatesConstr]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [O_DatesConstr] CHECK  (([OrderDate]<isnull([FinalizedDate],'9999-12-31 23:59:59') AND [OrderDate]<isnull([ToBeIssuedDate],'9999-12-31 23:59:59')))
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [O_DatesConstr]
GO
ALTER TABLE [dbo].[Reservations]  WITH CHECK ADD  CONSTRAINT [R_DatesConstr] CHECK  (([DateTo]>[DateFrom]))
GO
ALTER TABLE [dbo].[Reservations] CHECK CONSTRAINT [R_DatesConstr]
GO
ALTER TABLE [dbo].[ReservationsParams]  WITH CHECK ADD  CONSTRAINT [WKConstr] CHECK  (([WK]>=(0)))
GO
ALTER TABLE [dbo].[ReservationsParams] CHECK CONSTRAINT [WKConstr]
GO
ALTER TABLE [dbo].[ReservationsParams]  WITH CHECK ADD  CONSTRAINT [WZConstr] CHECK  (([WZ]>=(0)))
GO
ALTER TABLE [dbo].[ReservationsParams] CHECK CONSTRAINT [WZConstr]
GO
ALTER TABLE [dbo].[Tables]  WITH CHECK ADD  CONSTRAINT [CapacityConstr] CHECK  (([Capacity]>=(0)))
GO
ALTER TABLE [dbo].[Tables] CHECK CONSTRAINT [CapacityConstr]
GO
/****** Object:  StoredProcedure [dbo].[AcceptReservation]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AcceptReservation]
	@ReservationID int,
	@TableID int = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Reservations WHERE @ReservationID = ReservationID)
		BEGIN;
			THROW 55555, 'Nie ma takiej rezerwacji', 1
		END
	DECLARE @NumOfSeats int
	SELECT @NumOfSeats = NumOfSeats FROM Reservations WHERE ReservationID = @ReservationID
	IF (@TableID IS NULL)
		BEGIN;
			SELECT TOP 1 @TableID = TableID FROM Tables WHERE Capacity>=@NumOfSeats ORDER BY Capacity ASC
		END	
	IF (@TableID IS NULL)
		BEGIN;
			THROW 55555, 'Brak wolnego stolika dla tylu osob', 2
		END
	UPDATE Reservations
	SET Accepted = 1,
		TableID = @TableID
	WHERE @ReservationID = ReservationID
END
GO
/****** Object:  StoredProcedure [dbo].[AddBusinessClient]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBusinessClient]
	@Phone varchar(50),
	@Email varchar(50),
	@CompanyName varchar(50),
	@NIP varchar(50),
	@Street varchar(50),
	@CityName varchar(50),
	@PostalCode varchar(50),
	@CountryName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM Clients WHERE @Phone = Phone)
		BEGIN;
			THROW 55555, 'Ten numer juz jest w bazie', 1
		END
	IF EXISTS(SELECT * FROM Clients WHERE @Email = Email)
		BEGIN;
			THROW 55555, 'Ten email juz jest w bazie', 2
		END
	IF EXISTS(SELECT * FROM BusinessClient WHERE @NIP = NIP)
		BEGIN;
			THROW 55555, 'Ten NIP juz jest w bazie', 3
		END
	DECLARE @ClientID INT
	SELECT @ClientID = ISNULL(MAX(ClientID), 0) + 1
	FROM Clients
	DECLARE @CityID INT
	SELECT @CityID = CityID
	FROM Cities
	WHERE @CityName = CityName
	DECLARE @CountryID INT
	SELECT @CountryID = CountryID
	FROM Countries
	WHERE @CountryName = CountryName
	INSERT INTO Clients(ClientID, Phone, Email)
	VALUES (@ClientID, @Phone, @Email)
	INSERT INTO BusinessClient(ClientID, CompanyName, NIP, Street, CityID, PostalCode, CountryID)
	VALUES (@ClientID, @CompanyName, @NIP, @Street, @CityID, @PostalCode, @CountryID)
END
GO
/****** Object:  StoredProcedure [dbo].[AddBusReservation]    Script Date: 26.05.2023 20:48:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBusReservation]
	@ClientID int,
	@NumOfSeats int,
	@DateFrom datetime = NULL,
	@DateTo datetime = NULL,
	@GuestList varchar(2000) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	DECLARE @ReservationID int
	SELECT @ReservationID = ISNULL(MAX(ReservationID), 0) + 1
	FROM Reservations
	IF NOT EXISTS (SELECT * FROM BusinessClient WHERE @ClientID = ClientID)
		BEGIN;
			THROW 55555, 'Nie ma takiego klienta biznesowego', 1
		END

	IF (@DateFrom IS NULL)
		BEGIN;
			SELECT @DateFrom = GETDATE()
			SELECT @DateTo = DATEADD(hour, 3, @DateFrom)
		END
	INSERT INTO Reservations(ReservationID, TableID, NumOfSeats, DateFrom, DateTo, Accepted, Cancelled)
	VALUES(@ReservationID, NULL, @NumOfSeats, @DateFrom, @DateTo, 0, 0)
	INSERT INTO ReservationsBusiness(ReservationID, ClientID, GuestList)
	VALUES(@ReservationID, @ClientID, @GuestList)
	COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[AddCategory]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCategory]
	@CategoryName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM Categories WHERE @CategoryName = CategoryName)
		BEGIN;
			THROW 55555, 'Ta Kategoria już istnieje', 1
		END
	DECLARE @CategoryID INT
	SELECT @CategoryID = ISNULL(MAX(CategoryID), 0) + 1
	FROM Categories
	INSERT INTO Categories(CategoryID, CategoryName)
	VALUES(@CategoryID, @CategoryName);
END
GO
/****** Object:  StoredProcedure [dbo].[AddCity]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCity]
	@CityName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM Cities WHERE @CityName = CityName)
		BEGIN;
			THROW 55555, 'Takie panstwo juz jest w bazie', 1
		END
	DECLARE @CityID INT
	SELECT @CityID = ISNULL(MAX(CityID), 0) + 1
	FROM Cities
	INSERT INTO Cities(CityID, CityName)
	VALUES(@CityID, @CityName)
END
GO
/****** Object:  StoredProcedure [dbo].[AddCountry]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCountry]
	@CountryName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM Countries WHERE @CountryName = CountryName)
		BEGIN;
			THROW 55555, 'Takie panstwo juz jest w bazie', 1
		END
	DECLARE @CountryID INT
	SELECT @CountryID = ISNULL(MAX(CountryID), 0) + 1
	FROM Countries
	INSERT INTO Countries(CountryID, CountryName)
	VALUES(@CountryID, @CountryName)
END
GO
/****** Object:  StoredProcedure [dbo].[AddDiscount]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddDiscount]
	@ClientID int,
	@Type bit
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM IndividualClient WHERE @ClientID = ClientID)
		BEGIN;
			THROW 55555, 'Nie ma takiego klienta indywidualnego', 1
		END
	DECLARE @DiscountID INT
	SELECT @DiscountID = ISNULL(MAX(DiscountID), 0) + 1
	FROM Discounts
	DECLARE @DiscountParamsID INT
	SELECT @DiscountParamsID = DiscountParamsID 
	FROM DiscountParams
	WHERE DateTo IS NULL
	INSERT INTO Discounts(DiscountID, ClientID, Type, DiscountParamsID, UsedDate)
	VALUES(@DiscountID, @ClientID, @Type, @DiscountParamsID, GETDATE());
END
GO
/****** Object:  StoredProcedure [dbo].[AddIndividualClient]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddIndividualClient]
	@Phone varchar(50),
	@Email varchar(50),
	@FirstName varchar(50),
	@LastName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM Clients WHERE @Phone = Phone)
		BEGIN;
			THROW 55555, 'Ten numer juz jest w bazie', 1
		END
	IF EXISTS(SELECT * FROM Clients WHERE @Email = Email)
		BEGIN;
			THROW 55555, 'Ten email juz jest w bazie', 2
		END
	DECLARE @ClientID INT
	SELECT @ClientID = ISNULL(MAX(ClientID), 0) + 1
	FROM Clients
	INSERT INTO Clients(ClientID, Phone, Email)
	VALUES (@ClientID, @Phone, @Email)
	INSERT INTO IndividualClient(ClientID, FirstName, LastName)
	VALUES (@ClientID, @FirstName, @LastName)
END
GO
/****** Object:  StoredProcedure [dbo].[AddIndReservation]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddIndReservation]
	@ClientID int,
	@OrderID int,
	@NumOfSeats int,
	@DateFrom datetime = NULL,
	@DateTo datetime = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ClientOrderCount int
	DECLARE @ClientOrderValue float
	SELECT @ClientOrderValue = dbo.GetClientOrderValue(@ClientID)
	SELECT @ClientOrderCount = dbo.GetClientOrderCount(@ClientID)
	DECLARE @WZ int
	DECLARE @WK int
	SELECT @WK = WK FROM ReservationsParams
	SELECT @WZ = WZ FROM ReservationsParams
	IF (@ClientOrderCount<@WZ OR @ClientOrderValue<@WK)
		BEGIN;
			THROW 55555, 'Klient nie spelnia warunkow do zlozenia rezerwacji', 1
		END
	IF (@NumOfSeats<2)
		BEGIN;
			THROW 55555, 'Rezerwacje mozna zlozyc dla co najmniej dwoch osob', 2
		END
	DECLARE @ReservationID int
	SELECT @ReservationID = ISNULL(MAX(ReservationID), 0) + 1
	FROM Reservations
	IF (@DateFrom IS NULL)
		BEGIN;
			SELECT @DateFrom = GETDATE()
			SELECT @DateTo = DATEADD(hour, 3, @DateFrom)
		END
	IF (@DateTo IS NULL)
		BEGIN;
			SELECT @DateTo = DATEADD(hour, 3, @DateFrom)
		END
	BEGIN TRANSACTION
	INSERT INTO Reservations(ReservationID, TableID, NumOfSeats, DateFrom, DateTo, Accepted, Cancelled)
	VALUES(@ReservationID, NULL, @NumOfSeats, @DateFrom, @DateTo, 0, 0)
	INSERT INTO ReservationsIndividual(ReservationID, ClientID, OrderID)
	VALUES(@ReservationID, @ClientID, @OrderID)
	COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[AddOrder]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddOrder]
	@ClientID int,
	@OrderDate varchar(50) = NULL,
	@FinalizedDate varchar(50) = NULL,
	@ToBeIssuedDate varchar(50) = NULL,
	@Paid bit = NULL,
	@ProductNumber int,
	@ProductList varchar(2000),
	@QuantityList varchar(200),
	@WithDiscount bit = NULL,
	@WithReservation bit = NULL,
	@NumOfSeats int = NULL,
	@DateFrom datetime = NULL,
	@DateTo datetime = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	IF NOT EXISTS(SELECT * FROM Clients WHERE @ClientID = ClientID)
		BEGIN;
			THROW 55555, 'Nie ma takiego klienta', 1
		END
	DECLARE @OrderID INT
	SELECT @OrderID = ISNULL(MAX(OrderID), 0) + 1
	FROM Orders
	IF (@OrderDate IS NULL)
		BEGIN
			SELECT @OrderDate = GETDATE()
		END
	IF (@WithReservation=1 AND @ClientID NOT IN (SELECT ClientID FROM IndividualClient))
		BEGIN;
			THROW 55555, 'Klient firmowy sklada rezerwacje osobno', 2
		END
	DECLARE @DiscountRate int = NULL
	IF (@WithDiscount=1 AND @ClientID NOT IN (SELECT ClientID FROM ActiveDiscounts))
		BEGIN;
			THROW 55555, 'Ten klient nie ma zadnych znizek', 3
		END
	IF (@WithDiscount=1)
		BEGIN;
			SELECT @DiscountRate = MAX(dbo.GetDiscountRate(DiscountID)) FROM ActiveDiscounts WHERE ClientID = @ClientID
		END
	IF (@WithReservation=1)
		BEGIN;
			EXEC AddIndReservation @ClientID, @OrderID, @NumOfSeats, @DateFrom, @DateTo
		END
	
	IF (3 IN (SELECT CategoryID FROM Products INNER JOIN (SELECT VALUE FROM STR_SPLIT(@ProductList, ',')) as V ON V.VALUE=Products.ProductName))
		BEGIN
			IF (@ToBeIssuedDate IS NULL OR DATEDIFF(day, @OrderDate, DATEADD(day, -DATEPART(WEEKDAY, @ToBeIssuedDate)+2, @ToBeIssuedDate))<0)
				BEGIN;
					THROW 55555, 'Owoce morza nalezy zamawiac z wyprzedzeniem', 4
				END
			IF (DATEPART(WEEKDAY, @ToBeIssuedDate)!=7 AND DATEPART(WEEKDAY, @ToBeIssuedDate)!=6 AND DATEPART(WEEKDAY, @ToBeIssuedDate)!=5)
				BEGIN;
					THROW 55555, 'Owoce morza mozna zamowic jedynie na czwartek, piatek, sobote', 5
				END
		END
		
	INSERT INTO Orders(OrderID, ClientID, OrderDate, FinalizedDate, ToBeIssuedDate, Paid, DiscountRate)
	VALUES (@OrderID, @ClientID, @OrderDate, @FinalizedDate, @ToBeIssuedDate, @Paid, @DiscountRate)
	DECLARE @I int = 0
	WHILE (@I<@ProductNumber)
		BEGIN
			DECLARE @ProductName varchar(50)
			DECLARE @Quantity int
			SELECT @ProductName = value FROM STR_SPLIT(@ProductList, ',') WHERE ordinal=@I
			SELECT @Quantity = CAST(value AS int) FROM STR_SPLIT(@QuantityList, ',') WHERE ordinal=@I
			EXEC AddToOrder @OrderID, @ProductName, @Quantity
			SET @I = @I+1
		END
	COMMIT 
END
GO
/****** Object:  StoredProcedure [dbo].[AddProduct]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddProduct]
	@ProductName varchar(50),
	@CategoryName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM Products WHERE @ProductName = ProductName)
		BEGIN;
			THROW 55555, 'Ten Produkt już istnieje', 1
		END
	IF NOT EXISTS(SELECT * FROM Categories WHERE @CategoryName = CategoryName)
		BEGIN;
			THROW 55555, 'Nie ma takiej kategorii', 2
		END
	DECLARE @ProductID INT
	SELECT @ProductID = ISNULL(MAX(ProductID), 0) + 1
	FROM Products
	DECLARE @CategoryID INT
	SELECT @CategoryID = CategoryID 
	FROM Categories
	WHERE @CategoryName = CategoryName
	INSERT INTO Products(ProductID, ProductName, CategoryID)
	VALUES(@ProductID, @ProductName, @CategoryID);
END
GO
/****** Object:  StoredProcedure [dbo].[AddTable]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddTable]
	@Capacity int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @TableID INT
	SELECT @TableID = ISNULL(MAX(TableID), 0) + 1
	FROM Tables
	INSERT INTO Tables(TableID, Capacity, Available)
	VALUES (@TableID, @Capacity, 1)
END
GO
/****** Object:  StoredProcedure [dbo].[AddToMenu]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddToMenu]
	@ProductName varchar(50),
	@UnitPrice money,
	@DateFrom date = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Products WHERE @ProductName = ProductName)
		BEGIN;
			THROW 55555, 'Ten Produkt nie istnieje', 1
		END
	DECLARE @ProductID INT
	SELECT @ProductID = ProductID 
	FROM Products
	WHERE @ProductName = ProductName
	IF EXISTS(SELECT * FROM Menu WHERE @ProductID = ProductID AND DateTo IS NULL)
		BEGIN;
			THROW 55555, 'Ten Produkt już jest w obecnym Menu', 2
		END
	DECLARE @MenuID INT
	SELECT @MenuID = ISNULL(MAX(MenuID), 0) + 1
	FROM Menu
	WHERE @ProductID = ProductID
	IF (@DateFrom IS NULL)
		BEGIN;
			SELECT @DateFrom = GETDATE()
		END
	INSERT INTO Menu(ProductID, DateFrom, DateTo, UnitPrice, MenuID)
	VALUES(@ProductID, @DateFrom, NULL, @UnitPrice, @MenuID);
END
GO
/****** Object:  StoredProcedure [dbo].[AddToOrder]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddToOrder]
	@OrderID int,
	@ProductName varchar(50),
	@Quantity int
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Orders WHERE @OrderID = OrderID)
		BEGIN;
			THROW 55555, 'Nie ma takiego zamowienia', 1
		END
	IF NOT EXISTS(SELECT * FROM Products WHERE @ProductName = ProductName)
		BEGIN;
			THROW 55555, 'Nie ma takiego produktu', 2
		END
	DECLARE @ProductID int
	SELECT @ProductID = ProductID FROM Products WHERE ProductName = @ProductName
	IF NOT EXISTS(SELECT * FROM Menu WHERE @ProductID = ProductID AND DateTo IS NULL)
		BEGIN;
			THROW 55555, 'Nie ma takiego produktu w aktualnym menu', 3
		END
	INSERT INTO OrderDetails(OrderID, ProductID, Quantity)
	VALUES (@OrderID, @ProductID, @Quantity)
END
GO
/****** Object:  StoredProcedure [dbo].[CancellReservation]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CancellReservation]
	@ReservationID int
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Reservations WHERE @ReservationID = ReservationID)
		BEGIN;
			THROW 55555, 'Nie ma takiej rezerwacji', 1
		END
	UPDATE Reservations
	SET Cancelled = 1
	WHERE @ReservationID = ReservationID
END
GO
/****** Object:  StoredProcedure [dbo].[ChangeDiscParams]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeDiscParams]
	@OrderCountZ1 int,
	@OrderPriceK1 int,
	@DiscountR1 int,
	@SumK2 int, 
	@DiscountR2 int,
	@DurationD1 int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @DiscountParamsID INT
	SELECT @DiscountParamsID = ISNULL(MAX(DiscountParamsID), 0) + 1
	FROM DiscountParams
	UPDATE DiscountParams
	SET DateTo = GETDATE()
	WHERE DateTo IS NULL
	DECLARE @DateFrom datetime
	SELECT @DateFrom = GETDATE()
	INSERT INTO DiscountParams(OrderCountZ1, OrderPriceK1, DiscountR1, SumK2,
								DiscountR2, DurationD1, DiscountParamsID, DateFrom, DateTo)
	VALUES (@OrderCountZ1, @OrderPriceK1, @DiscountR1, @SumK2, @DiscountR2, @DurationD1, @DiscountParamsID, @DateFrom, NULL)
END
GO
/****** Object:  StoredProcedure [dbo].[CheckMenu]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckMenu]
AS
BEGIN
	SET NOCOUNT ON;
	IF ((SELECT COUNT(ProductName) FROM MenuList)<=(SELECT COUNT(ProductName) FROM ProductsToDelete)*2)
		BEGIN;
			THROW 55555, 'Menu jest przestarzale', 1
		END
END
GO
/****** Object:  StoredProcedure [dbo].[DeleteFromMenu]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteFromMenu]
	@ProductName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Products WHERE @ProductName = ProductName)
		BEGIN;
			THROW 55555, 'Ten Produkt nie istnieje', 1
		END
	DECLARE @ProductID INT
	SELECT @ProductID = ProductID 
	FROM Products
	WHERE @ProductName = ProductName
	IF NOT EXISTS(SELECT * FROM Menu WHERE @ProductID = ProductID AND DateTo IS NULL)
		BEGIN;
			THROW 55555, 'Tego Produktu nie ma w aktualnym Menu', 2
		END
	DECLARE @MenuID INT
	SELECT @MenuID = MenuID
	FROM Menu
	WHERE @ProductID = ProductID AND DateTo IS NULL
	UPDATE Menu
	SET DateTo = GETDATE()
	WHERE ProductID = @ProductID AND MenuID = @MenuID
END
GO
/****** Object:  StoredProcedure [dbo].[FinalizeOrder]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FinalizeOrder]
	@OrderID int,
	@FinalizedDate varchar(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Orders WHERE @OrderID = OrderID)
		BEGIN;
			THROW 55555, 'Nie ma takiego zamowienia', 1
		END
	IF (@FinalizedDate IS NULL)
		BEGIN;
			SELECT @FinalizedDate = GETDATE()
		END
	UPDATE Orders
	SET FinalizedDate = @FinalizedDate,
		Paid = 1
	WHERE @OrderID = OrderID
END
GO
/****** Object:  StoredProcedure [dbo].[ModReservParams]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ModReservParams]
	@WZ int,
	@WK int, 
	@ReservationsParamsID int = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM ReservationsParams WHERE @ReservationsParamsID = ReservationsParamsID)
		BEGIN;
			THROW 55555, 'Nie ma takiej rezerwacji', 1
		END
	IF (@ReservationsParamsID IS NULL)
		BEGIN;
			SELECT @ReservationsParamsID = 1
		END
	UPDATE ReservationsParams
	SET WZ = @WZ,
		WK = @WK
	WHERE @ReservationsParamsID = ReservationsParamsID
END
GO
/****** Object:  StoredProcedure [dbo].[ModTableAvailable]    Script Date: 26.05.2023 20:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ModTableAvailable]
	@TableID int,
	@Available bit
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS(SELECT * FROM Tables WHERE @TableID = TableID)
		BEGIN;
			THROW 55555, 'Ten stolik nie istnieje', 1
		END
	UPDATE Tables
	SET Available = @Available
	WHERE @TableID = TableID
END
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Discounts"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 264
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "DiscountParams"
            Begin Extent = 
               Top = 7
               Left = 312
               Bottom = 170
               Right = 528
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ActiveDiscounts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ActiveDiscounts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Discounts"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 280
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AssignedDiscMonthly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AssignedDiscMonthly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Discounts"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 280
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AssignedDiscWeekly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AssignedDiscWeekly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Clients"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "BusinessClient"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 170
               Right = 488
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Cities"
            Begin Extent = 
               Top = 7
               Left = 536
               Bottom = 126
               Right = 730
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Countries"
            Begin Extent = 
               Top = 7
               Left = 778
               Bottom = 126
               Right = 972
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'BusClientStats'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'BusClientStats'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ActiveDiscounts"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 126
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "IndividualClient"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 148
               Right = 516
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrBestDiscount'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrBestDiscount'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "DiscountParams"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 264
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrDiscParams'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrDiscParams'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "OrderDetails"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Menu"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 170
               Right = 516
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 564
               Bottom = 148
               Right = 774
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrMenuStats'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrMenuStats'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Tables"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'FreeTables'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'FreeTables'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Clients"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "IndividualClient"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 148
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'IndClientStats'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'IndClientStats'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 266
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LostOnDiscMonthly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LostOnDiscMonthly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 266
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LostOnDiscWeekly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LostOnDiscWeekly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Menu"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 170
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'MenuList'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'MenuList'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "A"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 170
               Right = 524
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'OrdersInfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'OrdersInfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 266
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'OrdersPerMonth'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'OrdersPerMonth'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 266
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'OrdersPerWeekDay'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'OrdersPerWeekDay'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OD"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 148
               Right = 516
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "O"
            Begin Extent = 
               Top = 7
               Left = 564
               Bottom = 170
               Right = 782
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProdMonthlyReport'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProdMonthlyReport'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Categories"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 126
               Right = 485
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductInfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductInfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Menu"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 148
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "P"
            Begin Extent = 
               Top = 7
               Left = 532
               Bottom = 126
               Right = 726
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductsToDelete'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductsToDelete'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "OrderDetails"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductTimesSoldAllTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductTimesSoldAllTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "OrderDetails"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 170
               Right = 524
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductTimesSoldLastMonth'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProductTimesSoldLastMonth'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 148
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OD"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 148
               Right = 516
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "O"
            Begin Extent = 
               Top = 7
               Left = 564
               Bottom = 170
               Right = 782
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProdWeeklyReport'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ProdWeeklyReport'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Reservations"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 2
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservationInfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservationInfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Reservations"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservStatsMonthly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservStatsMonthly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Reservations"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservStatsWeekly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservStatsWeekly'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Reservations"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservToAccept'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReservToAccept'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 266
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OD"
            Begin Extent = 
               Top = 7
               Left = 314
               Bottom = 148
               Right = 524
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "P"
            Begin Extent = 
               Top = 7
               Left = 572
               Bottom = 148
               Right = 782
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'SeaFoodNextWeek'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'SeaFoodNextWeek'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Orders"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 250
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UnpaidOrders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UnpaidOrders'
GO
USE [master]
GO
ALTER DATABASE [u_pczech] SET  READ_WRITE 
GO
