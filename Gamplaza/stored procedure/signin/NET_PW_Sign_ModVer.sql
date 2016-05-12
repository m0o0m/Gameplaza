	ALTER PROCEDURE [dbo].[NET_PW_Sign_Test]
@UserID INT,
    @BqNum INT, --��ǩ�ڼ���  Ĭ��ֵ��0,�������ǲ�ǩ
    @Flag INT,  --0��ȡ�����ǩ����Ϣ��1ִ�и����ǩ������
    @strErrorDescribe	NVARCHAR(127) OUTPUT--�����Ϣ
    AS
    -----------------------------------------��������-----------------------------------------
    SET NOCOUNT ON
    -----------------------------------------��������-----------------------------------------
    BEGIN
DECLARE @tlbSignDayStatus table(DayNum int, SignedStatus int, SignDate DATETIME)
    DECLARE @DayCnt int, @ScoreToday int
    DECLARE @Type INT,@LastSignDate DATETIME,@Continuous INT,@IsAllDaySigned INT  --@FirstSignDate DATETIME,@Score INT,@GetDAY INT,
    DECLARE @OneDay INT,@TwoDay INT,@ThreeDay INT,@FourDay INT,@FiveDay INT,@SixDay INT,@SevenDay INT,@AllDay INT,@BqScore INT
    DECLARE @Day1 INT,@Day2 INT,@Day3 INT,@Day4 INT,@Day5 INT,@Day6 INT,@Day7 INT, @ReturnValue INT
    DECLARE @SignToday INT 		--�����ǩ���ڼ���
    DECLARE @BSignType INT 		--��ǩ����0 , ��ʾ��ͨǩ��, 1��ʾ��ǩ
    DECLARE	@SignDate DATETIME 	--����ǩ��������
    DECLARE	@BSignDate DATETIME	
    -----------------------------------------��ʼ��-------------------------------------------
    SET @Day1=0 --0��δǩ��  1��ǩ��
    SET @Day3=0
    SET @Day2=0
    SET @Day4=0
    SET @Day5=0
    SET @Day6=0
    SET @Day7=0
    SET @IsAllDaySigned=0
    SET @SignToday=1
    SET @BSignType=0
    SET @BSignDate=0
		SET @SignDate=GETDATE()
    SELECT @Type=[Type],@OneDay=OneDay,@TwoDay=TwoDay,@ThreeDay=ThreeDay,@FourDay=FourDay,@FiveDay=FiveDay,@SixDay=SixDay,@SevenDay=SevenDay,@AllDay=AllDay,@BqScore=BqScore FROM QPTreasureDB.dbo.SignDay(NOLOCK) WHERE ID=1
    INSERT @tlbSignDayStatus (DayNum, SignDate) SELECT Continuous,SignDate FROM QPTreasureDB.dbo.SignLog(NOLOCK) WHERE UserID=@UserID
    SELECT TOP 1 @Continuous=DayNum,@LastSignDate=SignDate FROM @tlbSignDayStatus ORDER BY SignDate DESC
IF(@Continuous IS NULL)
    BEGIN
    SET @Continuous=0
    END
    -----------------------------------------------------------------------------
IF(@Type = 0)
    BEGIN
IF (DATEDIFF(DAY, CONVERT(NVARCHAR(10),@LastSignDate,120),CONVERT(NVARCHAR(10),GETDATE(),120))=0)
    BEGIN
    SET @SignToday=@Continuous;
    END
    ELSE
    BEGIN
    SET @SignToday=@Continuous+1;
    END
    END
    -----------------------------------------------------------------------------
IF(@Flag=0)
    BEGIN
    UPDATE @tlbSignDayStatus Set SignedStatus = 1 
    SET @DayCnt = 1;--ѭ������               
WHILE(@DayCnt <= 7)
    BEGIN
    IF NOT EXISTS (SELECT DayNum FROM @tlbSignDayStatus WHERE DayNum=@DayCnt) 
    BEGIN
    INSERT @tlbSignDayStatus (DayNum, SignedStatus) VALUES (@DayCnt, 0)
    END
    SET @DayCnt = @DayCnt + 1
    END
    SELECT @Day1 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=1
    SELECT @Day2 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=2
    SELECT @Day3 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=3
    SELECT @Day4 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=4
    SELECT @Day5 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=5
    SELECT @Day6 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=6
    SELECT @Day7 = SignedStatus FROM @tlbSignDayStatus WHERE DayNum=7
    SELECT @Day1 AS Day1,@Day2 AS Day2,@Day3 AS Day3,@Day4 AS Day4,@Day5 AS Day5,@Day6 AS Day6,@Day7 AS Day7,@Type AS IsBq,@OneDay AS OneDay,@TwoDay AS TwoDay,@ThreeDay AS ThreeDay,@FourDay AS FourDay,@FiveDay AS FiveDay,@SixDay AS SixDay,@SevenDay AS SevenDay,@AllDay AS AllDay,@BqScore AS BqScore, @Continuous AS Continuous, @SignToday AS SignToday
    SET @strErrorDescribe=N'���ݲ�ѯ�ɹ�'
    SET @ReturnValue=22
    RETURN @ReturnValue
    END
ELSE IF(@Flag=1)
        BEGIN
/* IF EXISTS (SELECT UserID FROM QPTreasureDB.dbo.SignLog(NOLOCK) WHERE UserID=@UserID AND CONVERT(NVARCHAR(10),SignDate,120)=CONVERT(NVARCHAR(10),GETDATE(),120)) --AND (@BqNum=0) */
IF EXISTS (SELECT DayNum FROM @tlbSignDayStatus WHERE CONVERT(NVARCHAR(10),SignDate,120)=CONVERT(NVARCHAR(10),GETDATE(),120)) --AND (@BqNum=0)
    BEGIN
    SET @strErrorDescribe=N'������ǩ����'
    SET @ReturnValue=25
    RETURN @ReturnValue
    END
    ----��ǩ��Ҳ����ж�
    ELSE
    BEGIN			
    SET  @ScoreToday= CASE  
    WHEN @Continuous=0 THEN @OneDay  
    WHEN @Continuous=1 THEN @TwoDay  
    WHEN @Continuous=2 THEN @ThreeDay  
    WHEN @Continuous=3 THEN @FourDay
    WHEN @Continuous=4 THEN @FiveDay
    WHEN @Continuous=5 THEN @SixDay
    WHEN @Continuous=6 THEN @SevenDay
    WHEN @Continuous=7 THEN @OneDay
    ELSE @OneDay  
    END  
    UPDATE QPTreasureDB.dbo.GameScoreInfo SET Score=Score+@ScoreToday,ALLScore=ALLScore+@ScoreToday WHERE UserID=@UserID
    INSERT INTO QPTreasureDB.dbo.SignLog(UserID,Score,SignDate,SignType,Continuous,BSignDate) VALUES(@UserID,@ScoreToday,@SignDate,@BSignType,@SignToday,@BSignDate)
IF EXISTS (SELECT ID FROM QPTreasureDB.dbo.SignScore(NOLOCK) WHERE CONVERT(NVARCHAR(10),AddTime,120)=CONVERT(NVARCHAR(10),GETDATE(),120))
    BEGIN
UPDATE QPTreasureDB.dbo.SignScore SET Score=Score+@ScoreToday WHERE CONVERT(NVARCHAR(10),AddTime,120)=CONVERT(NVARCHAR(10),GETDATE(),120)
    END
    ELSE
    BEGIN
INSERT INTO QPTreasureDB.dbo.SignScore(Score,AddTime) VALUES(@ScoreToday,GETDATE())
    END
    SET @strErrorDescribe=N'ǩ���ɹ���'
    IF(SELECT COUNT(UserID) FROM QPTreasureDB.dbo.SignLog(NOLOCK) WHERE UserID=@UserID AND Continuous IN (1,2,3,4,5,6,7))=7
    BEGIN
    SET @IsAllDaySigned=1;
    UPDATE QPTreasureDB.dbo.GameScoreInfo SET Score=Score+@AllDay WHERE UserID=@UserID
    END
    SET @ReturnValue=24
    SELECT @IsAllDaySigned AS IsAllDaySigned
    RETURN @ReturnValue
    END
    END
    END
