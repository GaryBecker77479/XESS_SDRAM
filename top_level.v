
/********************************************************************************
* SDRAM Interface
*********************************************************************************/
//      -- Host side
sdramCntl SDRAM(
.clk(CLK50MHZ),                 //in  std_logic;  -- master clock
.lock(RESET_N),                 //in  std_logic;  -- true if clock is stable
.rst(CPU_RESET),                //in  std_logic;  -- reset
.rd(SDRAM_RD),                  //in  std_logic;  -- initiate read operation
.wr(SDRAM_WR),                  //in  std_logic;  -- initiate write operation
.earlyOpBegun(SDRAM_EOB),       //out std_logic;  -- read/write/self-refresh op has begun (async)
.opBegun(SDRAM_OB),             //out std_logic;  -- read/write/self-refresh op has begun (clocked)
.rdPending(SDRAM_RDP),          //out std_logic;  -- true if read operation(s) are still in the pipeline
.done(SDRAM_DONE),              //out std_logic;  -- read or write operation is done
.rdDone(SDRAM_RDD),             //out std_logic;  -- read operation is done and data is available
.hAddr(SDRAM_ADDR),             //in  std_logic_vector(HADDR_WIDTH-1 downto 0);  -- address from host to SDRAM
.hDIn(SDRAM_DIN),               //in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- data from host to SDRAM
.hDOut(HDOUT),                  //out std_logic_vector(DATA_WIDTH-1 downto 0);  -- data from SDRAM to host
.status(SDRAM_STATUS),          //out std_logic_vector(3 downto 0);  -- diagnostic status of the FSM
//      -- SDRAM side
.cke(SDRAM_CKE),                //out std_logic;  -- clock-enable to SDRAM
.ce_n(SDRAM_CS_N),              //out std_logic;  -- chip-select to SDRAM
.ras_n(SDRAM_RAS_N),            //out std_logic;  -- SDRAM row address strobe
.cas_n(SDRAM_CAS_N),            //out std_logic;  -- SDRAM column address strobe
.we_n(SDRAM_RW_N),              //out std_logic;  -- SDRAM write enable
.ba(SDRAM_BANK),                //out std_logic_vector(1 downto 0);  -- SDRAM bank address
.sAddr(SDRAM_ADDRESS),          //out std_logic_vector(SADDR_WIDTH-1 downto 0);  -- SDRAM row/column address
.sDIn(SDRAM_DATA),              //in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- data from SDRAM
.sDOut(SDRAM_DATA_BUF),         //out std_logic_vector(DATA_WIDTH-1 downto 0);  -- data to SDRAM
.sDOutEn(SDRAM_DATA_BUF_EN),    //out std_logic;  -- true if data is output to SDRAM on sDOut
.dqmh(SDRAM_UDQM),              //out std_logic;  -- enable upper-byte of SDRAM databus if true
.dqml(SDRAM_LDQM)               //out std_logic  -- enable lower-byte of SDRAM databus if true
);

assign SDRAM_CLK = CLK50MHZ;
assign SDRAM_DATA = (SDRAM_DATA_BUF_EN)     ?   SDRAM_DATA_BUF:
                                                16'bZZZZZZZZZZZZZZZZ;

always @ (posedge CLK50MHZ or negedge RESET_N)
begin
    if(!RESET_N)
    begin
        SDRAM_STATE <= 3'b000;
        SDRAM_RD <= 1'b0;
        SDRAM_WR <= 1'b0;
        SDRAM_DOUT <= 16'h0000;
        SDRAM_START_BUF <= 2'b00;
    end
    else
    begin
        SDRAM_START_BUF <= {SDRAM_START_BUF[0], SDRAM_START};
        case (SDRAM_STATE)
        3'b000:
        begin
            if(!SDRAM_START_BUF[1])
                SDRAM_STATE <= 3'b001;
        end
        3'b001:
        begin
            if(SDRAM_START_BUF[1])
            begin
                if(SDRAM_READ)
                begin
                    SDRAM_STATE <= 3'b010;
                    SDRAM_RD <= 1'b1;
                end
                else
                begin
                    SDRAM_STATE <= 3'b101;
                    SDRAM_WR <= 1'b1;
                end
            end
        end
// Read
        3'b010:
        begin
            if(SDRAM_OB)
            begin
                SDRAM_RD <= 1'b0;
                if(SDRAM_DONE)
                    SDRAM_STATE <= 3'b100;
                else
                    SDRAM_STATE <= 3'b011;
            end
        end
        3'b011:
        begin
            if(SDRAM_DONE)
                SDRAM_STATE <= 3'b100;
        end
        3'b100:
        begin
            SDRAM_DOUT <= HDOUT;
            SDRAM_STATE <= 3'b000;
        end
// Write
        3'b101:
        begin
            if(SDRAM_OB)
            begin
                SDRAM_WR <= 1'b0;
                if(SDRAM_DONE)
                    SDRAM_STATE <= 3'b000;
                else
                    SDRAM_STATE <= 3'b110;
            end
        end
        3'b110:
        begin
            if(SDRAM_DONE)
            begin
                SDRAM_STATE <= 3'b000;
            end
        end
        3'b111:
        begin
            SDRAM_STATE <= 3'b000;
        end
        endcase
    end
end

always @ (negedge CLK50MHZ or negedge RESET_N)
begin
    if(!RESET_N)
    begin
        SDRAM_ADDR[6:0] <= 7'h00;
        SDRAM_START <= 1'b0;
        SDRAM_NEXT_BUF <= 2'b00;
        SDRAM_READY_BUF <= 2'b00;
    end
    else
    begin
        SDRAM_NEXT_BUF <= {SDRAM_NEXT_BUF[0], (SDRAM_STATE == 3'b000)};
        SDRAM_READY_BUF <= {SDRAM_READY_BUF[0], (SDRAM_STATE == 3'b001)};
        if(ADDRESS[15:0] == 16'hFF88)
            SDRAM_ADDR[6:0] <= 7'h7F;        // Set to -1 because we increment before the first operation
        else
            if(ADDRESS[15:0] == 16'hFF86)       // Does not matter if read or write
            begin
                SDRAM_ADDR[6:0] <= SDRAM_ADDR[6:0] + 1'b1;
                SDRAM_START <= 1'b1;
            end
            else
                if(SDRAM_NEXT_BUF[1])
                    SDRAM_START <= 1'b0;
    end
end
