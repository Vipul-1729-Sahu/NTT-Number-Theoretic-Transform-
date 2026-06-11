`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.05.2026 18:29:42
// Design Name: 
// Module Name: zeta_ROM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//Theory for my future reference :

//we don't use Zeta value at index 0 
//it's not required in Butterfly structure
//formula : zeta[k] = 17^bit_reverse_7(k) mod 3329

module zeta_ROM(                 // contains precalculated values of zeta
    input [7:0]index,                     // index value to access zeta value
    output [11:0]zeta_value
);
reg [11:0] zetas [0:127];

initial begin
    zetas[0]   = 12'd2285;  // -1044 mod 3329
    zetas[1]   = 12'd2571;  // -758 mod 3329
    zetas[2]   = 12'd2970;  // -359 mod 3329
    zetas[3]   = 12'd1812;  // -1517 mod 3329
    zetas[4]   = 12'd1493;
    zetas[5]   = 12'd1422;
    zetas[6]   = 12'd287;
    zetas[7]   = 12'd202;
    zetas[8]   = 12'd3158;  // -171 mod 3329
    zetas[9]   = 12'd622;
    zetas[10]  = 12'd1577;
    zetas[11]  = 12'd182;
    zetas[12]  = 12'd962;
    zetas[13]  = 12'd2127;  // -1202 mod 3329
    zetas[14]  = 12'd1855;  // -1474 mod 3329
    zetas[15]  = 12'd1468;

    zetas[16]  = 12'd573;
    zetas[17]  = 12'd2004;  // -1325 mod 3329
    zetas[18]  = 12'd264;
    zetas[19]  = 12'd383;
    zetas[20]  = 12'd2500;  // -829 mod 3329
    zetas[21]  = 12'd1458;
    zetas[22]  = 12'd1727;  // -1602 mod 3329
    zetas[23]  = 12'd3199;  // -130 mod 3329
    zetas[24]  = 12'd2648;  // -681 mod 3329
    zetas[25]  = 12'd1017;
    zetas[26]  = 12'd732;
    zetas[27]  = 12'd608;
    zetas[28]  = 12'd1787;  // -1542 mod 3329
    zetas[29]  = 12'd411;
    zetas[30]  = 12'd3124;  // -205 mod 3329
    zetas[31]  = 12'd1758;  // -1571 mod 3329

    zetas[32]  = 12'd1223;
    zetas[33]  = 12'd652;
    zetas[34]  = 12'd2777;  // -552 mod 3329
    zetas[35]  = 12'd1015;
    zetas[36]  = 12'd2036;  // -1293 mod 3329
    zetas[37]  = 12'd1491;
    zetas[38]  = 12'd3047;  // -282 mod 3329
    zetas[39]  = 12'd1785;  // -1544 mod 3329
    zetas[40]  = 12'd516;
    zetas[41]  = 12'd3321;  // -8 mod 3329
    zetas[42]  = 12'd3009;  // -320 mod 3329
    zetas[43]  = 12'd2663;  // -666 mod 3329
    zetas[44]  = 12'd1711;  // -1618 mod 3329
    zetas[45]  = 12'd2167;  // -1162 mod 3329
    zetas[46]  = 12'd126;
    zetas[47]  = 12'd1469;

    zetas[48]  = 12'd2476;  // -853 mod 3329
    zetas[49]  = 12'd3239;  // -90 mod 3329
    zetas[50]  = 12'd3058;  // -271 mod 3329
    zetas[51]  = 12'd830;
    zetas[52]  = 12'd107;
    zetas[53]  = 12'd1908;  // -1421 mod 3329
    zetas[54]  = 12'd3082;  // -247 mod 3329
    zetas[55]  = 12'd2378;  // -951 mod 3329
    zetas[56]  = 12'd2931;  // -398 mod 3329
    zetas[57]  = 12'd961;
    zetas[58]  = 12'd1821;  // -1508 mod 3329
    zetas[59]  = 12'd2604;  // -725 mod 3329
    zetas[60]  = 12'd448;
    zetas[61]  = 12'd2264;  // -1065 mod 3329
    zetas[62]  = 12'd677;
    zetas[63]  = 12'd2054;  // -1275 mod 3329

    zetas[64]  = 12'd2226;  // -1103 mod 3329
    zetas[65]  = 12'd430;
    zetas[66]  = 12'd555;
    zetas[67]  = 12'd843;
    zetas[68]  = 12'd2078;  // -1251 mod 3329
    zetas[69]  = 12'd871;
    zetas[70]  = 12'd1550;
    zetas[71]  = 12'd105;
    zetas[72]  = 12'd422;
    zetas[73]  = 12'd587;
    zetas[74]  = 12'd177;
    zetas[75]  = 12'd3094;  // -235 mod 3329
    zetas[76]  = 12'd3038;  // -291 mod 3329
    zetas[77]  = 12'd2869;  // -460 mod 3329
    zetas[78]  = 12'd1574;
    zetas[79]  = 12'd1653;

    zetas[80]  = 12'd3083;  // -246 mod 3329
    zetas[81]  = 12'd778;
    zetas[82]  = 12'd1159;
    zetas[83]  = 12'd3182;  // -147 mod 3329
    zetas[84]  = 12'd2552;  // -777 mod 3329
    zetas[85]  = 12'd1483;
    zetas[86]  = 12'd2727;  // -602 mod 3329
    zetas[87]  = 12'd1119;
    zetas[88]  = 12'd1739;  // -1590 mod 3329
    zetas[89]  = 12'd644;
    zetas[90]  = 12'd2457;  // -872 mod 3329
    zetas[91]  = 12'd349;
    zetas[92]  = 12'd418;
    zetas[93]  = 12'd329;
    zetas[94]  = 12'd3173;  // -156 mod 3329
    zetas[95]  = 12'd3254;  // -75 mod 3329

    zetas[96]  = 12'd817;
    zetas[97]  = 12'd1097;
    zetas[98]  = 12'd603;
    zetas[99]  = 12'd610;
    zetas[100] = 12'd1322;
    zetas[101] = 12'd2044;  // -1285 mod 3329
    zetas[102] = 12'd1864;  // -1465 mod 3329
    zetas[103] = 12'd384;
    zetas[104] = 12'd2114;  // -1215 mod 3329
    zetas[105] = 12'd3193;  // -136 mod 3329
    zetas[106] = 12'd1218;
    zetas[107] = 12'd1994;  // -1335 mod 3329
    zetas[108] = 12'd2455;  // -874 mod 3329
    zetas[109] = 12'd220;
    zetas[110] = 12'd2142;  // -1187 mod 3329
    zetas[111] = 12'd1670;  // -1659 mod 3329

    zetas[112] = 12'd2144;  // -1185 mod 3329
    zetas[113] = 12'd1799;  // -1530 mod 3329
    zetas[114] = 12'd2051;  // -1278 mod 3329
    zetas[115] = 12'd794;
    zetas[116] = 12'd1819;  // -1510 mod 3329
    zetas[117] = 12'd2475;  // -854 mod 3329
    zetas[118] = 12'd2459;  // -870 mod 3329
    zetas[119] = 12'd478;
    zetas[120] = 12'd3221;  // -108 mod 3329
    zetas[121] = 12'd3021;  // -308 mod 3329
    zetas[122] = 12'd996;
    zetas[123] = 12'd991;
    zetas[124] = 12'd958;
    zetas[125] = 12'd1869;  // -1460 mod 3329
    zetas[126] = 12'd1522;
    zetas[127] = 12'd1628;
end

assign zeta_value=zetas[index];

endmodule
