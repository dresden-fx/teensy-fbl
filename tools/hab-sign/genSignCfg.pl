#!/usr/bin/perl -w

#####################################################################
#
#####################################################################

use strict;
use File::Basename;
use Cwd qw(cwd);
use Switch;

# Create command arguments from arguments given to this scipt and undefine
# the script's arguments
my @cmdArgs = @ARGV;
undef @ARGV;

# Definition of all functions used by this script


my $HAB_TAG_IVT = 0xd1;       #/*!< Image Vector Table */
my $HAB_TAG_DCD = 0xd2;       #/*!< Device Configuration Data */
my $HAB_TAG_CSF = 0xd4;       #/*!< Command Sequence File */
my $HAB_TAG_CRT = 0xd7;       #/*!< Certificate */
my $HAB_TAG_SIG = 0xd8;       #/*!< Signature */
my $HAB_TAG_EVT = 0xdb;       #/*!< Event */
my $HAB_TAG_RVT = 0xdd;       #/*!< ROM Vector Table */
my $HAB_TAG_WRP = 0x81;       #/*!< Wrapped Key */
my $HAB_TAG_MAC = 0xac;       #/*!< Message Authentication Code */

my $HAB_CMD_SET_ITEM = 0xb1;  #/**< Set Item */
my $HAB_CMD_INS_KEY = 0xbe;   #/**< Install Key */
my $HAB_CMD_AUTH_DATA = 0xca; #/**< Authenticate Data */
my $HAB_CMD_WRT_DATA = 0xcc;  #/**< Write Data */
my $HAB_CMD_CHK_DATA = 0xcf;  #/**< Check Data */
my $HAB_CMD_NOP = 0xc0;       #/**< No Operation */
my $HAB_CMD_INIT = 0xb4;      #/**< Initialize */
my $HAB_CMD_UNLOCK = 0xb2;    #/**< Unlock */

my $HAB_CTX_ANY = 0x00;       #/**< Match any context in hab_rvt.report_event() */
my $HAB_CTX_FAB = 0xff;       #/**< @rom Event logged in hab_fab_test() */
my $HAB_CTX_ENTRY = 0xe1;     #/**< Event logged in hab_rvt.entry() */
my $HAB_CTX_TARGET = 0x33;    #/**< Event logged in hab_rvt.check_target() */
my $HAB_CTX_AUTH = 0x0a;      #/**< Event logged in hab_rvt.authenticate_image() */
my $HAB_CTX_DCD = 0xdd;       #/**< Event logged in hab_rvt.run_dcd() */
my $HAB_CTX_CSF = 0xcf;       #/**< Event logged in hab_rvt.run_csf() */
my $HAB_CTX_CMD = 0xc0;       #/**< Event logged executing CSF or DCD command */
my $HAB_CTX_AUTH_DATA = 0xdb; #/**< Authenticated data block */
my $HAB_CTX_ASSERT = 0xa0;    #/**< Event logged in hab_rvt.assert() */
my $HAB_CTX_EXIT = 0xee;      #/**< Event logged in hab_rvt.exit() */

my $HAB_ENG_ANY = 0x00;       #/**< First compatible engine will be selected automatically (no engine configuration parameters are allowed) */
my $HAB_ENG_SCC = 0x03;       #/**< Security controller */
my $HAB_ENG_RTIC = 0x05;      #/**< Run-time integrity checker */
my $HAB_ENG_SAHARA = 0x06;    #/**< Crypto accelerator */
my $HAB_ENG_CSU = 0x0a;       #/**< Central Security Unit */
my $HAB_ENG_SRTC = 0x0c;      #/**< Secure clock */
my $HAB_ENG_DCP = 0x1b;       #/**< Data co-processor */
my $HAB_ENG_CAAM = 0x1d;      #/**< Cryptographic Acceleration and Assurance Module */
my $HAB_ENG_SNVS = 0x1e;      #/**< Secure non-volatile storage */
my $HAB_ENG_OCOTP = 0x21;     #/**< Fuse controller */
my $HAB_ENG_DTCP = 0x22;      #/**< DTCP co-processor */
my $HAB_ENG_ROM = 0x36;       #/**< Protected ROM area */
my $HAB_ENG_HDCP = 0x24;      #/**< HDCP co-processor */
my $HAB_ENG_SW = 0xff;        #/**< Software engine */

my $HAB_PCL_SRK = 0x03;       #/**< SRK certificate format */
my $HAB_PCL_X509 = 0x09;      #/**< X.509v3 certificate format */
my $HAB_PCL_CMS = 0xc5;       #/**< CMS/PKCS#7 certificate format */
my $HAB_PCL_BLOB = 0xbb;      #/**< SHW-specific wrapped key format */
my $HAB_PCL_AEAD = 0xa3;      #/**< Proprietary AEAD MAC format */

my $HAB_ALG_ANY = 0x00;       #/**< Algorithm type ANY */
my $HAB_ALG_HASH = 0x01;      #/**< Hash algorithm type */
my $HAB_ALG_SIG = 0x02;       #/**< Signature algorithm type */
my $HAB_ALG_FF = 0x03;        #/**< Finite field arithmetic */
my $HAB_ALG_EC = 0x04;        #/**< Elliptic curve arithmetic */
my $HAB_ALG_CIPHER = 0x05;    #/**< Cipher algorithm type */
my $HAB_ALG_MODE = 0x06;      #/**< Cipher/hash mode */
my $HAB_ALG_WRAP = 0x07;      #/**< Key wrap algorithm type */
my $HAB_ALG_SHA1 = 0x11;      #/**< SHA-1 algorithm */
my $HAB_ALG_SHA256 = 0x17;    #/**< SHA-256 algorithm */
my $HAB_ALG_SHA512 = 0x1b;    #/**< SHA-512 algorithm */
my $HAB_ALG_PKCS1 = 0x21;     #/**< PKCS#1 RSA signature algorithm */
my $HAB_ALG_AES = 0x55;       #/**< AES algorithm */
my $HAB_ALG_CCM_MODE = 0x66;  #/**< Counter with CBC-MAC */
my $HAB_ALG_BLOB = 0x71;      #/**< SHW-specific key wrap algorithm */

my $HAB_KEY_PUBLIC = 0xe1;    #/** Public key type: data present */
my $HAB_KEY_HASH = 0xee;      #/** Any key type: hash only */

my $HAB_HDR_SIZE = 0x04;      # Size of HAB header
my $HAB_IVT_SIZE = 0x20;      # Size of IVT data structure
my $HAB_BOOT_SIZE = 0x0C;     # Size of boot data structure



###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_getTagStr
{
  my $tag = $_[0];

  my $tagStr;  
  switch($tag)
  {
  case ($HAB_TAG_IVT) {$tagStr = "IVT";}
  case ($HAB_TAG_DCD) {$tagStr = "DCD";}
  case ($HAB_TAG_CSF) {$tagStr = "CSF";}
  case ($HAB_TAG_CRT) {$tagStr = "CRT";}
  case ($HAB_TAG_SIG) {$tagStr = "SIG";}
  case ($HAB_TAG_EVT) {$tagStr = "EVT";}
  case ($HAB_TAG_RVT) {$tagStr = "RVT";}
  case ($HAB_TAG_WRP) {$tagStr = "WRP";}
  case ($HAB_TAG_MAC) {$tagStr = "MAC";}
  else                {$tagStr = "Unknown!";}
  }
  return $tagStr;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_getCmdStr
{
  my $cmdTag = $_[0];

  my $cmdStr;
  switch($cmdTag)
  {
  case ($HAB_CMD_SET_ITEM)  {$cmdStr = "SET_ITEM";}
  case ($HAB_CMD_INS_KEY)   {$cmdStr = "INS_KEY";}
  case ($HAB_CMD_AUTH_DATA) {$cmdStr = "AUTH_DATA";}
  case ($HAB_CMD_WRT_DATA)  {$cmdStr = "WRT_DATA";}
  case ($HAB_CMD_CHK_DATA)  {$cmdStr = "CHK_DATA";}
  case ($HAB_CMD_NOP)       {$cmdStr = "NOP";}
  case ($HAB_CMD_INIT)      {$cmdStr = "INIT";}
  case ($HAB_CMD_UNLOCK)    {$cmdStr = "UNLOCK";}
  else                      {$cmdStr = "Unknown!";}
  }
  return $cmdStr;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_getEngineStr
{
  my $engTag = $_[0];

  my $engineStr;
  switch($engTag)
  {
  case ($HAB_ENG_ANY)    {$engineStr = "ANY";}
  case ($HAB_ENG_SCC)    {$engineStr = "SCC";}
  case ($HAB_ENG_RTIC)   {$engineStr = "RTIC";}
  case ($HAB_ENG_SAHARA) {$engineStr = "SAHARA";}
  case ($HAB_ENG_CSU)    {$engineStr = "CSU";}
  case ($HAB_ENG_SRTC)   {$engineStr = "SRTC";}
  case ($HAB_ENG_DCP)    {$engineStr = "DCP";}
  case ($HAB_ENG_CAAM)   {$engineStr = "CAAM";}
  case ($HAB_ENG_SNVS)   {$engineStr = "SNVS";}
  case ($HAB_ENG_OCOTP)  {$engineStr = "OTOCP";}
  case ($HAB_ENG_DTCP)   {$engineStr = "DTCP";}
  case ($HAB_ENG_ROM)    {$engineStr = "ROM";}
  case ($HAB_ENG_HDCP)   {$engineStr = "HDCP";}
  case ($HAB_ENG_SW)     {$engineStr = "SW";}
  else                   {$engineStr = "Unknown!";}
  }
  return $engineStr;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_getProtocolStr
{
  my $pclTag = $_[0];

  my $protocolStr;
  switch($pclTag)
  {
  case ($HAB_PCL_SRK)  {$protocolStr = "SRK";}
  case ($HAB_PCL_X509) {$protocolStr = "X509";}
  case ($HAB_PCL_CMS)  {$protocolStr = "CMS";}
  case ($HAB_PCL_BLOB) {$protocolStr = "BLOB";}
  case ($HAB_PCL_AEAD) {$protocolStr = "AEAD";}
  else                 {$protocolStr = "Unknown!";}
  }
  return $protocolStr;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_getAlgorithmStr
{
  my $algTag = $_[0];

  my $algorithmStr;
  switch($algTag)
  {
  case ($HAB_ALG_ANY)      {$algorithmStr = "ANY";}
  case ($HAB_ALG_HASH)     {$algorithmStr = "HASH";}
  case ($HAB_ALG_SIG)      {$algorithmStr = "SIG";}
  case ($HAB_ALG_FF)       {$algorithmStr = "FF";}
  case ($HAB_ALG_EC)       {$algorithmStr = "ECC";}
  case ($HAB_ALG_CIPHER)   {$algorithmStr = "CIPHER";}
  case ($HAB_ALG_MODE)     {$algorithmStr = "MODE";}
  case ($HAB_ALG_WRAP)     {$algorithmStr = "WRAP";}
  case ($HAB_ALG_SHA1)     {$algorithmStr = "SHA1";}
  case ($HAB_ALG_SHA256)   {$algorithmStr = "SHA256";}
  case ($HAB_ALG_SHA512)   {$algorithmStr = "SHA512";}
  case ($HAB_ALG_PKCS1)    {$algorithmStr = "PKCS1";}
  case ($HAB_ALG_AES)      {$algorithmStr = "AES";}
  case ($HAB_ALG_CCM_MODE) {$algorithmStr = "CCM";}
  case ($HAB_ALG_BLOB)     {$algorithmStr = "BLOB";}
  else                     {$algorithmStr = "Unknown!";}
  }
  return $algorithmStr;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_getKeyTypeStr
{
  my $keyTag = $_[0];

  my $keyTypeStr;
  switch($keyTag)
  {
  case ($HAB_KEY_PUBLIC) {$keyTypeStr = "PUBKEY";}
  case ($HAB_KEY_HASH)   {$keyTypeStr = "KEYHASH";}
  else                   {$keyTypeStr = "Unknown!";}
  }
  return $keyTypeStr;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_parseHdr
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $hdr = $_[2];

  # Extract IVT header value
  $hdr->{"header"} = unpack("x".$offs."V", $buf);

  # Extract tag, length and version as "U8:U16be:U8"
  ($hdr->{"tag"}, $hdr->{"size"}, $hdr->{"ver"}) = unpack("x".$offs." C n C", $buf);

  # Gather major and minor version
  $hdr->{"majVer"} = $hdr->{"ver"} >> 4;
  $hdr->{"minVer"} = $hdr->{"ver"} & 0x0F;

  printf("\n  Tag: 0x%02X -> %s", $hdr->{"tag"}, hab_getTagStr($hdr->{"tag"}));
  printf("\n  Len: 0x%04X -> %d Bytes", $hdr->{"size"}, $hdr->{"size"});
  printf("\n  Ver: 0x%02X -> HABVer: %d.%d\n", $hdr->{"ver"}, $hdr->{"majVer"}, $hdr->{"minVer"});
}


###############################################################################
# hab_parseDataBlk($buffer, $offs, \%blkRef)
###############################################################################
#
#
###############################################################################

sub hab_parseDataBlk
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $blk = $_[2];

  # Extract block values
  ($blk->{"addr"}, $blk->{"size"}) = unpack("x".$offs." N N", $buf);

  printf("\n  BlkAddr: 0x%08X", $blk->{"addr"});
  printf("\n  BlkSize: 0x%08X (%d Bytes)", $blk->{"size"}, $blk->{"size"});
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub hab_parseIvt
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $ivt = $_[2];


  hab_parseHdr($buf, $offs, $ivt);

  # Check validity of IVT
  if($ivt->{"tag"} != $HAB_TAG_IVT)
  {
    # Invalid IVT tag
    printf("BLUB1\n");
  }
  elsif($ivt->{"size"} != $HAB_IVT_SIZE)
  {
    # Invalid IVT len
    printf("BLUB2\n");
  }
  elsif($ivt->{"majVer"} != 4)
  {
    # Invalid major version
    printf("BLUB3\n");
  }
  else
  {
    printf("\n Tag: 0x%02X -> %s", $ivt->{"tag"}, hab_getTagStr($ivt->{"tag"}));
    printf("\n Len: 0x%04X -> %d Bytes", $ivt->{"size"}, $ivt->{"size"});
    printf("\n Ver: 0x%02X -> HABVer: %d.%d\n", $ivt->{"ver"}, $ivt->{"majVer"}, $ivt->{"minVer"});

    # IVT is valid so extract IVT fields
    ($ivt->{"entryAddr"}, $ivt->{"dcdAddr"}, $ivt->{"bootAddr"}, $ivt->{"selfAddr"}, $ivt->{"csfAddr"}) = unpack("x".$offs." V x4 V V V V x4", $buf);

    # Give some info about read IVT
#    printf("  Header:    0x%08X (Tag=0x%02X Len=0x%04X (%d Bytes), Ver=0x%02X\n", $ivt->{"header"}, $ivt->{"tag"}, $ivt->{"size"}, $ivt->{"size"}, $ivt->{"ver"});
    printf("  Entry:     0x%08X\n", $ivt->{"entryAddr"});
    printf("  DCD:       0x%08X\n", $ivt->{"dcdAddr"});
    printf("  Boot Data: 0x%08X\n", $ivt->{"bootAddr"});
    printf("  Self:      0x%08X\n", $ivt->{"selfAddr"});
    printf("  CSF:       0x%08X\n", $ivt->{"csfAddr"});
  }
}


###############################################################################
# hab_parseInsKeyCmd($buffer, $offs, \%cmdRef)
###############################################################################
#
#
###############################################################################

sub hab_parseInsKeyCmd
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $cmd = $_[2];

  my $flagsStr = "";
  
  for(my $i = 0; $i < 8; $i++)
  {
    if($cmd->{"par"} & (1 << $i))
    {
      $flagsStr = $flagsStr."1 ";
    }
    else
    {
      $flagsStr = $flagsStr."0 ";
    }
  }
  
  printf("\n  Flags:   %s", $flagsStr);
  printf("\n           H C M F C D C A");
  printf("\n           S I I I F A S B");
  printf("\n           H D D D G T F S");

  # Extract command values
  $offs += $HAB_HDR_SIZE;
  ($cmd->{"pcl"}, $cmd->{"alg"}, $cmd->{"src"}, $cmd->{"tgt"}, $cmd->{"keyAddr"}) = unpack("x".$offs." C C C C N", $buf);

  printf("\n  Proto:   0x%02X -> %s", $cmd->{"pcl"}, hab_getProtocolStr($cmd->{"pcl"}));
  printf("\n  Algo:    0x%02X -> %s", $cmd->{"alg"}, hab_getAlgorithmStr($cmd->{"alg"}));
  printf("\n  Src:     0x%02X", $cmd->{"src"});
  printf("\n  Tgt:     0x%02X", $cmd->{"tgt"});
  printf("\n  KeyAddr: 0x%08X", $cmd->{"keyAddr"});
}


###############################################################################
# hab_parseAuthDataCmd($buffer, $offs, \%cmdRef)
###############################################################################
#
#
###############################################################################

sub hab_parseAuthDataCmd
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $cmd = $_[2];
  
  my $bytesRemaining = $cmd->{"size"};

  # Extract command values
  $offs += $HAB_HDR_SIZE;
  $bytesRemaining -= $HAB_HDR_SIZE;

  ($cmd->{"key"}, $cmd->{"pcl"}, $cmd->{"eng"}, $cmd->{"cfg"}) = unpack("x".$offs." C C C C", $buf);
  $offs += $HAB_HDR_SIZE;
  $bytesRemaining -= $HAB_HDR_SIZE;

  ($cmd->{"sigAddr"}) = unpack("x".$offs."N", $buf);
  $offs += $HAB_HDR_SIZE;
  $bytesRemaining -= $HAB_HDR_SIZE;

  printf("\n  Key:     0x%02X", $cmd->{"key"});
  printf("\n  Proto:   0x%02X -> %s", $cmd->{"pcl"}, hab_getProtocolStr($cmd->{"pcl"}));
  printf("\n  Engine:  0x%02X -> %s", $cmd->{"eng"}, hab_getEngineStr($cmd->{"eng"}));
  printf("\n  Config:  0x%02X", $cmd->{"cfg"});
  printf("\n  CrtAddr: 0x%08X", $cmd->{"sigAddr"});
  
  for(my $i = 0; $bytesRemaining > 0; $i++)
  {
    my $blk = {};

    hab_parseDataBlk($buf, $offs, $blk);
    push(@{$cmd->{"blks"}}, $blk);
    $offs += 2 * $HAB_HDR_SIZE;
    $bytesRemaining -= 2 * $HAB_HDR_SIZE;
  }
}


###############################################################################
# hab_parseUnlockCmd($buffer, $offs, \%cmdRef)
###############################################################################
#
#
###############################################################################

sub hab_parseUnlockCmd
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $cmd = $_[2];

  my $bytesRemaining = $cmd->{"size"};
  
  # Extract command values
  $offs += $HAB_HDR_SIZE;
  $bytesRemaining -= $HAB_HDR_SIZE;
  
  printf("\nParseUnlockCmd(Offs=%d, Size=%d)", $offs, $bytesRemaining);

  (@{$cmd->{"vals"}}) = unpack("x".$offs." C".$bytesRemaining, $buf);
  printf("\n  Engine:  0x%02X -> %s", $cmd->{"par"}, hab_getEngineStr($cmd->{"par"}));
  printf("\n  Values: (%d Bytes)", scalar(@{$cmd->{"vals"}}));
  trace_dump($cmd->{"vals"}, $bytesRemaining, 16, 2);
}


###############################################################################
# hab_parseCmd($buffer, $offs, \%cmdRef)
###############################################################################
#
#
###############################################################################

sub hab_parseCmd
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $cmd = $_[2];

  printf("\nhabParseCmd(offs=%d)\n", $offs);

  # Extract CMD header value
  ($cmd->{"header"}) = unpack("x".$offs." V", $buf);
#  printf("  Hdr: 0x%08X \n", $cmd->{"header"});

  # Extract tag, length and flags as "U8:U16be:U8"
  ($cmd->{"tag"}, $cmd->{"size"}, $cmd->{"par"}) = unpack("x".$offs." C n C", $buf);

  printf("  Tag: 0x%02X -> %s\n", $cmd->{"tag"}, hab_getCmdStr($cmd->{"tag"}));
  printf("  Len: 0x%04X -> %d Bytes\n", $cmd->{"size"}, $cmd->{"size"});
  printf("  Par: 0x%02X", $cmd->{"par"});
  
  switch($cmd->{"tag"})
  {
  case ($HAB_CMD_INS_KEY)   {hab_parseInsKeyCmd($buf, $offs, $cmd);}
  case ($HAB_CMD_AUTH_DATA) {hab_parseAuthDataCmd($buf, $offs, $cmd);}
  case ($HAB_CMD_UNLOCK)    {hab_parseUnlockCmd($buf, $offs, $cmd);}
  else {;}
  }
  printf("\n");
}


###############################################################################
# hab_parseCsf($buffer, $offs, \%csfRef)
###############################################################################
#
#
###############################################################################

sub hab_parseCsf
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $csf = $_[2];

  my $bytesRemaining;
  
  hab_parseHdr($buf, 0, $csf);

  # Check validity of CSF
  if($csf->{"tag"} != $HAB_TAG_CSF)
  {
    # Invalid CSF tag
  }
  elsif($csf->{"majVer"} != 4)
  {
    # Invalid major version
  }
  else
  {
#    printf("\n  Tag: 0x%02X -> %s", $csf->{"tag"}, hab_getTagStr($csf->{"tag"}));
#    printf("\n  Len: 0x%04X -> %d Bytes", $csf->{"size"}, $csf->{"size"});
#    printf("\n  Ver: 0x%02X -> HABVer: %d.%d\n", $csf->{"ver"}, $csf->{"majVer"}, $csf->{"minVer"});

    # Skip CSF header
    $bytesRemaining = $csf->{"size"};
    $bytesRemaining -= $HAB_HDR_SIZE;
    $offs += $HAB_HDR_SIZE;

    for(my $i = 0; $bytesRemaining > 0; $i++)
    {
      my $cmd = {};

      hab_parseCmd($buf, $offs, $cmd);
      push(@{$csf->{"cmds"}}, $cmd);
      $bytesRemaining -= $cmd->{"size"};
      $offs += $cmd->{"size"};
    }
  }
}


sub trace_dump
{
  my @buf = @{$_[0]};
  my $len = $_[1];
  my $width = $_[2];
  my $indent = $_[3];

  my $i;
  my $k;
  my $col = 0;
  
  for($k = 0; $k < $indent; $k++)
  {
    printf(" ");
  }

  for($i = 0; $i < $len; $i++)
  {
    $col++;
    
    if($i == $len - 1)
    {
      printf("%02x\n", $buf[$i]);
    }
    elsif($col < $width)
    {
      printf("%02x ", $buf[$i]);
    }
    else
    {
      $col = 0;
      printf("%02x\n", $buf[$i]);
      for($k = 0; $k < $indent; $k++)
      {
        printf(" ");
      }
    }
  }
}


###############################################################################
# hab_parseSrk($buffer, $offs, \%srkRef)
###############################################################################
#
#
###############################################################################

sub hab_parseSrk
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $srk = $_[2];

  trace_info(" ParseSrk(offs=%d)\n", $offs);

  # Extract SRK header value
  ($srk->{"header"}) = unpack("x".$offs." V", $buf);
#  trace_info("  Hdr: 0x%08X\n", $srk->{"header"});

  # Extract tag, length and flags as "U8:U16be:U8"
  ($srk->{"tag"}, $srk->{"size"}, $srk->{"par"}) = unpack("x".$offs." C n C", $buf);

  trace_info("\n  Tag: 0x%02X -> %s", $srk->{"tag"}, hab_getKeyTypeStr($srk->{"tag"}));
  trace_info("\n  Len: 0x%04X -> %d Bytes", $srk->{"size"}, $srk->{"size"});
  trace_info("\n  Par: 0x%02X -> %s", $srk->{"par"}, hab_getAlgorithmStr($srk->{"par"}));
  
  
  if($srk->{"tag"} != $HAB_KEY_PUBLIC)
  {
    # Invalid key type
  }
  else
  {
    my @data = unpack("x".$offs." C".$srk->{"size"}, $buf);
    $srk->{"data"} = pack("C*", unpack("x".$offs." C".$srk->{"size"}, $buf));   
    $srk->{"hash"} = sha256($srk->{"data"});

    $offs += $HAB_HDR_SIZE;
    ($srk->{"res0"}, $srk->{"res1"}, $srk->{"res2"}, $srk->{"caFlag"}) = unpack("x".$offs." C C C C", $buf);
	
    trace_info("\n  CA : 0x%02x\n", $srk->{"caFlag"});
    
    trace_info("  Data: (%d Bytes)\n", length($srk->{"data"}));
    trace_dump(\@data, $srk->{"size"}, 16, 2);

    $offs += $HAB_HDR_SIZE;    	
	  ($srk->{"keyLen"}, $srk->{"expLen"}) = unpack("x".$offs." n n", $buf);
#	trace_info("\n  keyLen: %d", $srk->{"keyLen"});
#	trace_info("\n  expLen: %d\n", $srk->{"expLen"});
	
    $offs += $HAB_HDR_SIZE;
    (@{$srk->{"key"}}) = unpack("x".$offs." C".$srk->{"keyLen"}, $buf);
	
    $offs += $srk->{"keyLen"};
    (@{$srk->{"exp"}}) = unpack("x".$offs." C".$srk->{"expLen"}, $buf);

    trace_info("  Key: (%d Bytes)\n", scalar(@{$srk->{"key"}}));
    trace_dump($srk->{"key"}, $srk->{"keyLen"}, 16, 2);
    trace_info("  Exp: (%d Bytes)\n", scalar(@{$srk->{"exp"}}));
    trace_dump($srk->{"exp"}, $srk->{"expLen"}, 16, 2);
    trace_info("  Hash:\n"); # unpack("H*", $srk->{"hash"})."\n"
    trace_info("  %s\n", unpack("H*", $srk->{"hash"}));
#    trace_info("  %s\n", unpack("(H2)*", $srk->{"hash"}));
#    trace_info("  %s\n", pack("(A2)*", unpack("H*", $srk->{"hash"})));
    #trace_dump(\unpack("C*", $srk->{"hash"}), 32, 16, 2);
  }
  trace_info("\n");
}


###############################################################################
# hab_parseSrkTbl($buffer, $offs, \%srkTblRef)
###############################################################################
#
#
###############################################################################

sub hab_parseSrkTbl
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $srkTbl = $_[2];

  my $bytesRemaining;
  
  hab_parseHdr($buf, 0, $srkTbl);

  # Check validity of header
  if($srkTbl->{"tag"} != $HAB_TAG_CRT)
  {
    # Invalid CRT tag
  }
  elsif($srkTbl->{"majVer"} != 4)
  {
    # Invalid major version
  }
  else
  {
#    trace_info("\n  Tag: 0x%02X -> %s", $srkTbl->{"tag"}, hab_getTagStr($srkTbl->{"tag"}));
#    trace_info("\n  Len: 0x%04X -> %d Bytes", $srkTbl->{"size"}, $srkTbl->{"size"});
#    trace_info("\n  Ver: 0x%02X -> HABVer: %d.%d\n", $srkTbl->{"ver"}, $srkTbl->{"majVer"}, $srkTbl->{"minVer"});

    # Skip CRT header
    $bytesRemaining = $srkTbl->{"size"};
    $bytesRemaining -= $HAB_HDR_SIZE;
    $offs += $HAB_HDR_SIZE;

    for(my $i = 0; $bytesRemaining > 0; $i++)
    {
      my $srk = {};

      hab_parseSrk($buf, $offs, $srk);
      push(@{$srkTbl->{"srks"}}, $srk);
      $offs += $srk->{"size"};
      $bytesRemaining -= $srk->{"size"};
    }
  }
}


###############################################################################
# hab_parseCmsSig($buffer, $offs, \%crtRef)
###############################################################################
#
#
###############################################################################

sub hab_parseCmsSig
{
  my $buf = $_[0];
  my $offs = $_[1];
  my $sig = $_[2];

  my $bytesRemaining;
  
  # Check validity of CSF
  if($sig->{"tag"} != $HAB_TAG_SIG)
  {
    # Invalid signature tag
  }
  elsif($sig->{"majVer"} != 4)
  {
    # Invalid major version
  }
  else
  {
    printf("\n Tag: 0x%02X -> %s", $sig->{"tag"}, hab_getTagStr($sig->{"tag"}));
    printf("\n Len: 0x%04X -> %d Bytes", $sig->{"size"}, $sig->{"size"});
    printf("\n Ver: 0x%02X -> HABVer: %d.%d\n", $sig->{"ver"}, $sig->{"majVer"}, $sig->{"minVer"});

    # Skip signature header
#    $bytesRemaining = $sig->{"size"} - $HAB_HDR_SIZE;
#    (my @s) = unpack("x".$offs." C".$bytesRemaining, $buf);
  
    # Open the binary image for read
    my $sigFilePath = "./";
    my $sigFileName = "tmp";
    my $sigFile;
    open($sigFile, ">", "$sigFilePath"."$sigFileName") or die "Failed to open: $sigFilePath"."$sigFileName $!";
    binmode($sigFile);
    print($sigFile $buf);
#    asn1Parse("$sigFilePath"."$sigFileName");

#    signImage();
#    for(my $i = 0; $bytesRemaining > 0; $i++)
#    {
#      my $srk = {};

#      hab_parseSrk($buf, $offs, $srk);
#      push(@{$srkTbl->{"srks"}}, $srk);
#      $offs += $srk->{"size"};
#	  $bytesRemaining -= $srk->{"size"};
#    }
  }
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub getCwd
{
  my @result;
  my $cmdStr = "pwd";
  my $pipe;
  my $line;
  my $pid;
  
  $pid = open($pipe, $cmdStr." |");
  while($line = <$pipe>)
  {
    # remove newline
    chomp($line);
    push(@result, $line);
  }
  close($pipe);
  return @result;
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub signImage
{
  my $cwd;
  my @result;
  my $cstProc;
  my $exit;
  my $line;
  my $pid;
  my $dir;
  
  
  $cwd = cwd();
  $dir = $cwd;
#  print("CST-home: ".$ENV{'CST_HOME'}."\n");
  chdir($ENV{'CST_HOME'}."/production") or die "Can't change directory: $!\n";
  $cwd = cwd();
  print("Executing CST-Tool from within ".$cwd."\n");
  
  $pid = open($cstProc, "cst -i cst.conf -o csf.bin |");

  while($line = <$cstProc>)
  {
    # remove newline
    chomp($line);
    # push to the result array
    push(@result, $line);
  }

  # Close the child process
  close($cstProc);

  # Examine the exit code of the child process
  $exit = $?;

  if($exit & 0xFF)
  {
    # The child process failed
    if($exit & 0x80)
    {
      warn("$0: pipe failed with core dump: exit=".($exit >> 8)." signal=".($exit & 0x7F)."\n");
    }
    else
    {
      warn("$0: pipe failed: exit=".($exit >> 8)." signal=".($exit & 0x7F)."\n");
    }

    if(scalar(@result))
    {
      die("failed with the following output:\n", join("\n", @result), "\n");
    }
    else
    {
      die("failed without any output.\n");
    }
  }

  if(0 < scalar(@result))
  {
    print("Output:\n  ", join("\n  ", @result), "\n");
  }
  # Change back to original directory
  chdir($dir) or die "Can't change directory: $!\n";
}


###############################################################################
#
###############################################################################
#
#
###############################################################################

sub makeHex
{
  my $srcPath;
  my $srcImgFile;
  my $dstImgFile;
  my $entryAddr;
  my $baseAddr;
  my @result;
  my $argList;
  my $pipe;
  my $exit;
  my $line;
  my $pid;
  my $dir;
  my $cwd;
  
  ($srcPath, $srcImgFile, $dstImgFile, $entryAddr, $baseAddr) = @_;
  $cwd = cwd();
  print("Executing objcpy from within ".$cwd."\n");
  printf("  Entry:     0x%08X\n", $entryAddr);
  printf("  Base:      0x%08X\n", $baseAddr);
  $entryAddr -= $baseAddr;
  
  $argList = "-I binary -O ihex --set-start ".$entryAddr." --change-address ".$baseAddr." ".$srcPath.$srcImgFile." ".$srcPath.$dstImgFile;
  $pid = open($pipe, "objcopy ".$argList."|");

  while($line = <$pipe>)
  {
    # remove newline
    chomp($line);
    # push to the result array
    push(@result, $line);
  }

  # Close the child process
  close($pipe);

  # Examine the exit code of the child process
  $exit = $?;

  if($exit & 0xFF)
  {
    # The child process failed
    if($exit & 0x80)
    {
      warn("$0: pipe failed with core dump: exit=".($exit >> 8)." signal=".($exit & 0x7F)."\n");
    }
    else
    {
      warn("$0: pipe failed: exit=".($exit >> 8)." signal=".($exit & 0x7F)."\n");
    }

    if(scalar(@result))
    {
      die("failed with the following output:\n", join("\n", @result), "\n");
    }
    else
    {
      die("failed without any output.\n");
    }
  }

  if(0 < scalar(@result))
  {
    print("\nOutput:\n  ", join("\n  ", @result), "\n\n");
  }
}


sub print_verbose1
{
  my $verbose = shift(@_);
  my $fmt = shift(@_);
  my @args = @_;
  
  if($verbose > 0)
  {
    printf($fmt, @args);
  }
}

# --ivt-offs=0x00000000
# --csf-align=0x1000
# --crc-offs=0x208
# --csf-pad=
# --srk-tbl=
# --noca-key=
# --csf-key=
# --img-key=
# --srk-idx=
# --noca-key=
# --csf-cert=
# --csfk-slot=
# --img-cert=
# --imgk-slot=

# Define help message for this script
my $helpMessage = <<"END_HELP";
 --input-file=<in-file-name>        Binary image to be signed
 --input-dir=<input-directory>      
 --expand-file=<file-name>          Name of the expanded file
 --output-file=<out-file-name>      Name of the output file
 --output-cfg=<out-cfg-file-name>   
 --image-type=MFG|FLS|MMC|BLOB      Create signed image for MFG-Tool(MFG), for persistent storage (FLS, MMC), image without IVT 
 --ivt-offs=0x00001000              Offset of the IVT in the given binary image
 --crc-offs=<crc-offset>            Where to patch the CRC
 --srk-tbl=<srk-tbl-file-name>      File name of the SRK table binary
 --srk-idx=<skr-index>              Index of the key in the SRK table (0..3)
 --noca-cert=<noca-cert-file-name>  
 --csfk-cert=<csfk-cert-file-name>  The certificate must be located in <cst-dir>/crts 
                                    and its name must match the key file in <cst-dir>/keys
                                    and the key must be in PKCS8 Format and the password 
                                    must be in the file <cst-dir>/keys/key_pass.txt
 --imgk-cert=<imgk-cert-file-name>  The certificate must be located in <cst-dir>/crts 
                                    and its name must match the key file in <cst-dir>/keys
                                    and the key must be in PKCS8 Format and the password 
                                    must be in the file <cst-dir>/keys/key_pass.txt
 --verbose                          Verbose output
END_HELP

# The image type determines the following aspects of the image signing:
# MFG:
#   An MFG image is expected to already contain a valid IVT at the offset
#   given by --ivt-offs. The offset depends on the target processor and
#   storage media.
#   As the image is split by the MFG-tool into 2 components during download,
#   with the first one being the DCD downloaded to and executed from a
#   target processor specific address, the signing target address needs to
#   be adapted appropriately in the generated CST configuration.
#   Also in order to not execute the DCD twice, the second component is the
#   remaining image with the DCD address in the IVT set to 0, which must
#   be taken into account before signature is calculated. Thus a modified
#   binary image is created to be feed into CST, which has the DCD address
#   set to 0.
# MMC:
#   A MMC image is expected to already contain a valid IVT at the offset
#   given by --ivt-offs. The offset depends on the target processor and
#   storage media.
#   A MMC image may or may not have a DCD. Anyway, if loaded from storage
#   media, the DCD is executed from the natural place given by image. So
#   the image doesn't need a modification of neither the IVT nor the DCD
#   address.
# BLOB:
#   A BLOB image is expected to have no IVT so the script will built an
#   IVT and prepend it to the given blob.
#   A BLOB image is expected to have no DCD at all.
#   A BLOB image is expected to have a size not necessarily aligned to any
#   specific boundary. As we want to align the start of the CSF to a
#   boundary given by --csf-align the a modified binary image is created to
#   be fed into CST, which adds some padding between the actual end of the
#   input image and the wished boundary.
#   As a BLOB image doesn't have an IVT it also has no load address and thus
#   that load address must be specified via --load-addr.

# Define the script's main function
# 
sub genSignCfg
{
  # Get arguments and argument count
  my @args = @_;
  my $argc = @args;

  my $i;
  # Name and path of image to be signed
  my $srcImgName = "image.bin"; # default name
  my $srcImgPath;
  
  # Name and path of image expanded
  my $expImgName = "image_exp.bin";
  my $expHexName = "image_exp.hex";
  my $expImgPath = $ENV{'CST_HOME'}."/production/";

  # Name and path of binary file used for signing
  my $dstImgName = "image_strip.bin";
  my $dstImgPath = $ENV{'CST_HOME'}."/production/";

  # Name of CST config file
  my $cstConf = "cst.conf";

  # Name of CST output file
  my $csfImgName = "csf.bin";

  my $imgType = "FLS";
  # Address of DCD in target memory
  my $dcdAddr = 0x00910000;
  # Multi-line string containing the CST config
  my $cstConfig;
  # Array getting the blocks definitions for the CST config
  my @blocks = {};

  # Size of input binary image
  my $imgSize;
  # Size of expanded output binary image
  my $expSize;
  # Size of padding to fit the alignment
  my $padSize;
  
  # Read pointer for given binary file
  my $imgPos;
  # Buffer used for read data from given binary file
  my $buf;

  # Buffer to hold read partition data
  my $partData = "";
  # Buffer to hold read, modified or generated IVT data
  my $ivtData = "";
  # Buffer to modified for signing IVT data
  my $sigIvtData = "";
  # Buffer to hold read, modified or generated boot data
  my $bootData = "";
  # Buffer to hold read DCD data
  my $dcdData = "";
  # Buffer to hold read application data
  my $appData = "";
  # Buffer to hold generated application padding data
  my $appPad = "";
  # Buffer to hold generated CSF data
  my $csfData = "";
  # Buffer to hold generated CSF padding
  my $csfPad = "";

  # Offset of the CRC within the given binary file.
  my $crcOffs;
  # Offset of the IVT within the given binary file.
  my $ivtOffs = 0x00001000;
  # Offset to the BOOT data within the given binary file.
  my $bootOffs;
  # Offset to the DCD within in the given binary file.
  my $dcdOffs;

  # Size of CRC
  my $crcSize;
  # Size of HAB header
  my $HAB_HDR_SIZE = 0x04;
  # Size of IVT data structure
  my $HAB_IVT_SIZE = 0x20;
  # Size of boot data structure
  my $HAB_BOOT_SIZE = 0x0C;
  # Size of DCD in source image if available
  my $dcdSize = 0;

  # ...
  my $blobLoadAddr = 0;
  my $bootPad = 0x04;
  my $csfAlign = 0x400;
  my $csfSize = 0x2000;

  # Struct to store IVT values
  my $ivt = {};
  # Struct to store boot values
  my $boot = {};
  # Struct to store DCD values
  my $dcd = {};

  my $srkNonCA = 0;
  my $srkTblFileName;
  my $srkIdx = 0;
  my $nocaCertFileName;
  my $imgkCertFileName;
  my $csfkCertFileName;
  my $csfkSlot = 0;
  my $imgkSlot = 1;

  my $imgFile;
  my $expFile;
  my $ivtFile;
  my $cstFile;
  my $csfFile;

  my $file;
  my $path;
  my $suffix;
  
  my $verbose = 0;

  if($argc > 0)
  {
    my $argID;
    my $argStr;
    # Parse arguments
    for($argID = 0; $argID < $argc; $argID++)
    {
      $argStr = $cmdArgs[$argID];
      if($argStr =~ m/--input-file=(.+)/)
      {
        ($file, $path, $suffix) = fileparse($1, qr/\.[^.]*/);
        $srcImgName = $file.$suffix;
        $srcImgPath = $path;
      }
      elsif($argStr =~ m/--ivt-offs=(.+)/)
      {
        my $offs = $1;
        if($offs =~ m/^0x([a-fA-F0-9]+)$/)
        {
          $ivtOffs = hex($1);
        }
        elsif($offs =~ m/^([0-9]+)$/)
        {
          $ivtOffs = $1;
        }
        else
        {
          print("Invalid format for IVT offset: ".$offs."\n");
          exit(-1);
        }
      }
      elsif($argStr =~ m/--crc-offs=(.+)/)
      {
        my $offs = $1;
        if($offs =~ m/^0x([a-fA-F0-9]+)$/)
        {
          $crcOffs = hex($1);
          $crcSize = 4;
        }
        elsif($offs =~ m/^([0-9]+)$/)
        {
          $crcOffs = $1;
          $crcSize = 4;
        }
        else
        {
          print("Invalid format for CRC offset: ".$offs."\n");
          exit(-1);
        }
      }
      elsif($argStr =~ m/--srk-tbl=(.+)/)
      {
        $srkTblFileName = $1;
      }
      elsif($argStr =~ m/--srk-idx=(.+)/)
      {
        my $idx = $1;
        if($idx =~ m/^([0-3])$/)
        {
          $srkIdx = $1;
        }
        else
        {
          print("Invalid SRK index: ".$idx."\n");
          print(" Allowed values: 0..3\n");
          exit(-1);
        }
      }
      elsif($argStr =~ m/--noca-cert=(.+)/)
      {
        $nocaCertFileName = $1;
        $srkNonCA = 1;
      }
      elsif($argStr =~ m/--csfk-cert=(.+)/)
      {
        $csfkCertFileName = $1;
      }
      elsif($argStr =~ m/--csfk-slot=(.+)/)
      {
        my $slot = $1;
        if($slot =~ m/^([0-3])$/)
        {
          $csfkSlot = $1;
        }
        else
        {
          print("Invalid CSFK slot: ".$slot."\n");
          exit(-1);
        }
      }
      elsif($argStr =~ m/--imgk-cert=(.+)/)
      {
        $imgkCertFileName = $1;
      }
      elsif($argStr =~ m/--imgk-slot=(.+)/)
      {
        my $slot = $1;
        if($slot =~ m/^([2-4])$/)
        {
          $imgkSlot = $1;
        }
        else
        {
          print("Invalid IMGK slot: ".$slot."\n");
          print(" Allowed values: 2..4\n");
          exit(-1);
        }
      }
      elsif($argStr =~ m/--image-type=(.+)/)
      {
        $imgType = $1;
        if($imgType =~ m/MFG/)
        {
          $dcdAddr = 0x00910000;
        }
        elsif($imgType =~ m/MMC/)
        {
          $dcdAddr = 0x00000000;
        }
        elsif($imgType =~ m/FLS/)
        {
          $dcdAddr = 0x00000000;
        }
        elsif($imgType =~ m/BLOB/)
        {
          $dcdAddr = 0x00910000;
        }
      }
      elsif($argStr =~ m/--verbose/)
      {
        $verbose = 1;
      }
      else
      {
        printf("Unknown argument.\n");
        print("$helpMessage\n");
        return -1;
      }
    }
  }
  else
  {
    print("$helpMessage\n");
    return -1;
  }
  
  # Check if source image exists
  if(-e "$srcImgPath/$srcImgName")
  {
    # Get image size
    $imgSize = (-s "$srcImgPath"."$srcImgName");
  }
  else
  {
    print("Source image ".$srcImgPath.$srcImgName." doesn't exist.\n");
    exit(-1);
  }

  # Open the binary image for read
  open($imgFile, "<", "$srcImgPath"."$srcImgName") or die "Failed to open: $srcImgPath"."$srcImgName $!";
  binmode($imgFile);

  printf("\nGenerating signing request...\n");
  printf("  FileName:  %s\n", $srcImgPath.$srcImgName);
  printf("  FileSize:  0x%08X (%d Bytes)\n", $imgSize, $imgSize);


  # Preset expanded size with image size
  $expSize = $imgSize;

  # Clear image position pointer
  $imgPos = 0;
  if($imgType =~ m/BLOB/)
  {
    # Image type is BLOB
    $expSize += $HAB_IVT_SIZE;  # Need to generate and add IVT
    $expSize += $HAB_BOOT_SIZE; # Need to generate and add BOOT data
    $expSize += $bootPad;       # Add boot padding if desired
  }
  else
  {
    # Other image type
  }
  
  # Calculate space to fill before the CSF in order to fit alignment
  $padSize = ($csfAlign - ($expSize % $csfAlign)) % $csfAlign;

  # Calculate final expanded size
  $expSize += $padSize;

  print_verbose1($verbose, "\nExpanding image...\n");
  if($padSize != 0)
  {
    print_verbose1($verbose, "  ExpSize = 0x%08X (%d Bytes)\n", $expSize, $expSize);
    # Fill the padding buffer
    for($i = 0; $i < $padSize; $i++)
    {
      $appPad .= pack("C", 0x5A);
    }
  }
  else
  {
    print_verbose1($verbose, "  No expansion necessary...\n");
  }


  if($imgType =~ m/BLOB/)
  {
    # Image type is BLOB

    # Clear out partition data
    $partData = "";

    # Create appropriate IVT content
    $ivt->{"tag"} = 0xD1;
    $ivt->{"size"} = $HAB_IVT_SIZE;
    $ivt->{"ver"} = 0x40;
    $ivt->{"header"} = unpack("V", pack("C n C", $ivt->{"tag"}, $ivt->{"size"}, $ivt->{"ver"}));
    $ivt->{"selfAddr"} = $blobLoadAddr;
    $ivt->{"csfAddr"} = $ivt->{"selfAddr"} + $expSize;
    $ivt->{"bootAddr"} = $ivt->{"selfAddr"} + $HAB_IVT_SIZE;
    $ivt->{"entryAddr"} = $ivt->{"bootAddr"} + $HAB_BOOT_SIZE + $bootPad;
    $ivt->{"dcdAddr"} = 0;

    # Print IVT info
    print_verbose1($verbose, "\nGenerate image vector table (IVT) for blob...\n");
    print_verbose1($verbose, "  Header:    0x%08X (Tag=0x%02X Len=0x%04X (%d Bytes), Ver=0x%02X\n", $ivt->{"header"}, $ivt->{"tag"}, $ivt->{"size"}, $ivt->{"size"}, $ivt->{"ver"});
    print_verbose1($verbose, "  Entry:     0x%08X\n", $ivt->{"entryAddr"});
    print_verbose1($verbose, "  DCD:       0x%08X\n", $ivt->{"dcdAddr"});
    print_verbose1($verbose, "  Boot Data: 0x%08X\n", $ivt->{"bootAddr"});
    print_verbose1($verbose, "  Self:      0x%08X\n", $ivt->{"selfAddr"});
    print_verbose1($verbose, "  CSF:       0x%08X\n\n", $ivt->{"csfAddr"});

    # Create appropriate boot data content
    $boot->{"startAddr"} = $blobLoadAddr;
    $boot->{"imgSize"} = $expSize + $csfSize;
    $boot->{"plugin"} = 0;
  
    # Print boot data info
    print_verbose1($verbose, "\nGenerate boot data for blob...\n");
    print_verbose1($verbose, "  Start:     0x%08X\n", $boot->{"startAddr"});
    print_verbose1($verbose, "  Length:    0x%08X\n", $boot->{"imgSize"});
    print_verbose1($verbose, "  Plugin:    0x%08X\n\n", $boot->{"plugin"});
    
    # Clear out DCD data
    $dcdData = "";
  }
  else
  {
    # Other image type

    # Read partition data which is all data up to $ivtOffs
    # This might be nothing if $ivtOffs is 0
    $imgPos += read($imgFile, $buf, $ivtOffs);
    # Save partition data for later reference
    $partData = $buf;

    # Here we expect to read the IVT
    $imgPos += read($imgFile, $buf, $HAB_IVT_SIZE);
    # Save IVT data for later reference
    $ivtData = $buf;


    # Extract header value
    $ivt->{"header"} = unpack("V", $buf);
    # Extract tag, length and version as "U8:U16be:U8"
    ($ivt->{"tag"}, $ivt->{"size"}, $ivt->{"ver"}) = unpack("C n C", $buf);
    # Gather major and minor version
    $ivt->{"majVer"} = $ivt->{"ver"} >> 4;
    $ivt->{"minVer"} = $ivt->{"ver"} & 0x0F;

    # Check validity of IVT
    if($ivt->{"tag"} != 0xD1)
    {
      # Invalid IVT tag
      print("Invalid IVT header (TAG) at offset: ".$ivtOffs."\n");
      exit(-1);
    }
    elsif($ivt->{"size"} != $HAB_IVT_SIZE)
    {
      # Invalid IVT len
      print("Invalid IVT header (LEN) at offset: ".$ivtOffs."\n");
      exit(-1);
    }
    elsif($ivt->{"majVer"} != 4)
    {
      # Invalid major version
      print("Invalid IVT header (VER) at offset: ".$ivtOffs."\n");
      exit(-3);
    }
    else
    {
      # IVT is valid so extract IVT fields
      ($ivt->{"entryAddr"}, $ivt->{"dcdAddr"}, $ivt->{"bootAddr"}, $ivt->{"selfAddr"}, $ivt->{"csfAddr"}) = unpack("x4 V x4 V V V V x4", $ivtData);

      # Give some info about read IVT
      print_verbose1($verbose, "\nFound valid image vector table (IVT) at offset 0x%08X...\n", $ivtOffs);
      print_verbose1($verbose, "  Header:    0x%08X (Tag=0x%02X Len=0x%04X (%d Bytes), Ver=0x%02X\n", $ivt->{"header"}, $ivt->{"tag"}, $ivt->{"size"}, $ivt->{"size"}, $ivt->{"ver"});
      print_verbose1($verbose, "  Entry:     0x%08X\n", $ivt->{"entryAddr"});
      print_verbose1($verbose, "  DCD:       0x%08X\n", $ivt->{"dcdAddr"});
      print_verbose1($verbose, "  Boot Data: 0x%08X\n", $ivt->{"bootAddr"});
      print_verbose1($verbose, "  Self:      0x%08X\n", $ivt->{"selfAddr"});
      print_verbose1($verbose, "  CSF:       0x%08X\n", $ivt->{"csfAddr"});
    }
    
    # Calculate offset within image, where to read the boot data
    $bootOffs = $ivtOffs - $ivt->{"selfAddr"} + $ivt->{"bootAddr"};
    
    # Check for and extract boot data
    print_verbose1($verbose, "Check for boot data...\n");
    if($ivt->{"bootAddr"} == 0)
    {
      # No boot data in the given binary
      print("No boot data address given in IVT.");
      exit(-1);
    }
    # Boot data is part of the binary
    elsif($bootOffs < $imgPos)
    {
      # Pointer to boot data points somewhere below the end of the IVT
      print("BOOT!!!!!!!");
      exit(-2);
    }
    else
    {
      # Read boot alignment (data between IVT and boot data)
      $imgPos += read($imgFile, $buf, $bootOffs - $imgPos);
      # Save for later reference
      $bootData .= $buf;
      # Read boot data
      $imgPos += read($imgFile, $buf, $HAB_BOOT_SIZE);
      # Save for later reference
      $bootData = $buf;


      # Extract boot fields as "U32le:U32le:U32le"
      ($boot->{"startAddr"}, $boot->{"imgSize"}, $boot->{"plugin"}) = unpack("V V V", $buf);

      # Give some info about read IVT
      print_verbose1($verbose, "  Found boot data at offset 0x%08X...\n", $bootOffs);
      print_verbose1($verbose, "  Start:     0x%08X\n", $boot->{"startAddr"});
      print_verbose1($verbose, "  Length:    0x%08X\n", $boot->{"imgSize"});
      print_verbose1($verbose, "  Plugin:    0x%08X\n\n", $boot->{"plugin"});
      print_verbose1($verbose, "n");
    }    


    # Calculate offset within image, where to read the DCD data
    $dcdOffs =  $ivtOffs - $ivt->{"selfAddr"} + $ivt->{"dcdAddr"};
 
    # Check for and extract device configuration data
    print_verbose1($verbose, "Check for device configuration data (DCD)...\n");
    if($ivt->{"dcdAddr"} == 0)
    {
      # Device config data is not part of the binary
      print_verbose1($verbose, "  No DCD address given in IVT.\n");
    }
    # Device config data is part of the binary
    elsif($dcdOffs < $imgPos)
    {
      # Pointer to device config data points somewhere below the end of the boot data
      print("DCD!!!!!!!");
      exit(-2);
    }
    else
    {
      # Read DCD alignment
      $imgPos += read($imgFile, $buf, $dcdOffs - $imgPos);
      $dcdData = $buf;

      # Read DCD header
      $imgPos += read($imgFile, $buf, $HAB_HDR_SIZE);  
      $dcdData .= $buf;
        
      # Extract DCD header
      $dcd->{"header"} = unpack("V", $buf);

      # Extract tag, length and par
      ($dcd->{"tag"}, $dcd->{"size"}, $dcd->{"par"}) = unpack("C n C", $buf);

      print_verbose1($verbose, "  Found DCD at offset 0x%08X...\n", $dcdOffs);
      print_verbose1($verbose, "  Header:    0x%08X (Tag=0x%02X Len=0x%04X (%d Bytes), Par=0x%02X\n", $dcd->{"header"}, $dcd->{"tag"}, $dcd->{"size"}, $dcd->{"size"}, $dcd->{"par"});
      
      $dcdSize = $dcd->{"size"};
    }
    print_verbose1($verbose, "\n");
    

    # Read remaining file
    $imgPos += read($imgFile, $buf, $imgSize - $imgPos);
    # Save for later reference
    $appData = $buf;

    # Close source image file
    close($imgFile);
  }

#  $ivt->{"csfAddr"} = $ivt->{"selfAddr"} + $expSize - $ivtOffs;
#  $boot->{"imgSize"} = $expSize + $csfSize; # TODO: is this correct?


  if($imgType =~ m/MFG/)
  {
    # As we have a target DCD address, the image is a MFG image
    # Rewrite IVT with stripped DCD address
    $ivt->{"sigDcdAddr"} = 0;
  }
  else
  {
    $ivt->{"sigDcdAddr"} = $ivt->{"dcdAddr"};
  }

  # Print IVT info
  print_verbose1($verbose, "Write image to be signed...\n");
  print_verbose1($verbose, "  DstPath:   %s\n", $dstImgPath.$dstImgName);
  print_verbose1($verbose, "\nImage vector table (IVT) at offset: 0x08X:\n", $ivtOffs);
  print_verbose1($verbose, "  Header:    0x%08X (Tag=0x%02X Len=0x%04X (%d Bytes), Ver=0x%02X\n", $ivt->{"header"}, $ivt->{"tag"}, $ivt->{"size"}, $ivt->{"size"}, $ivt->{"ver"});
  print_verbose1($verbose, "  Entry:     0x%08X\n", $ivt->{"entryAddr"});
  print_verbose1($verbose, "  DCD:       0x%08X\n", $ivt->{"sigDcdAddr"});
  print_verbose1($verbose, "  Boot Data: 0x%08X\n", $ivt->{"bootAddr"});
  print_verbose1($verbose, "  Self:      0x%08X\n", $ivt->{"selfAddr"});
  print_verbose1($verbose, "  CSF:       0x%08X\n", $ivt->{"csfAddr"});

  # Generate IVT
  $ivtData = pack("VVVVVVVV", $ivt->{"header"}, $ivt->{"entryAddr"}, 0, $ivt->{"sigDcdAddr"}, $ivt->{"bootAddr"}, $ivt->{"selfAddr"}, $ivt->{"csfAddr"}, 0);

  # Print boot data info
  print_verbose1($verbose, "\nBoot data at offset 0x%08X:\n", $bootOffs);
  print_verbose1($verbose, "  Start:     0x%08X\n", $boot->{"startAddr"});
  print_verbose1($verbose, "  Length:    0x%08X\n", $boot->{"imgSize"});
  print_verbose1($verbose, "  Plugin:    0x%08X\n", $boot->{"plugin"});

  # Generate boot data
#  $bootData = pack("VVVN", $boot->{"startAddr"}, $boot->{"imgSize"}, $boot->{"plugin"}, 0xAFFEDEAD);
  $bootData = pack("VVV", $boot->{"startAddr"}, $boot->{"imgSize"}, $boot->{"plugin"});

  # Create image to be fed into the CST tool
  open($ivtFile, ">", "$dstImgPath"."$dstImgName") or die "Failed to open: $!";
  binmode($ivtFile);
  print($ivtFile $partData);
  print($ivtFile $ivtData);
  print($ivtFile $bootData);
  print($ivtFile $appData);
  print($ivtFile $appPad);
  close($ivtFile);


  # Prepare block definition for signing configuration
  if( ($dcdAddr != 0) && ($dcdSize != 0) )
  {
    # The source binary contains DCD and the target type is MFG
    $blocks[0]->{"blkAddr"} = sprintf("0x%08X", $ivt->{"selfAddr"});
    $blocks[0]->{"blkOffs"} = sprintf("0x%08X", $ivtOffs);
    $blocks[0]->{"blkSize"} = sprintf("0x%08X", $ivt->{"dcdAddr"} - $ivt->{"selfAddr"});
    $blocks[0]->{"file"} = "\"$dstImgName\",\\";

    $blocks[1]->{"blkAddr"} = sprintf("0x%08X", $dcdAddr);
    $blocks[1]->{"blkOffs"} = sprintf("0x%08X", $dcdOffs);
    $blocks[1]->{"blkSize"} = sprintf("0x%08X", $dcdSize);
    $blocks[1]->{"file"} = "\"$dstImgName\",\\";

    $blocks[2]->{"blkAddr"} = sprintf("0x%08X", $ivt->{"dcdAddr"} + $dcdSize);
    $blocks[2]->{"blkOffs"} = sprintf("0x%08X", $dcdOffs + $dcdSize);
    $blocks[2]->{"blkSize"} = sprintf("0x%08X", $ivt->{"csfAddr"} - ($ivt->{"dcdAddr"} + $dcdSize));
    $blocks[2]->{"file"} = "\"$dstImgName\"";
  }
  # Either the target type is MMC/FLS or the source binary image doesn't contain DCD
  elsif(($crcSize != 0) && ($crcOffs > $ivtOffs))
  {
    # Create first chunk from IVT to CRC
    $blocks[0]->{"blkAddr"} = sprintf("0x%08X", $ivt->{"selfAddr"});
    $blocks[0]->{"blkOffs"} = sprintf("0x%08X", $ivtOffs);
    $blocks[0]->{"blkSize"} = sprintf("0x%08X", $crcOffs - $ivtOffs);
    $blocks[0]->{"file"} = "\"$dstImgName\",\\";
    
    # Create first chunk from CRC to CSF
    $blocks[1]->{"blkAddr"} = sprintf("0x%08X", $ivt->{"selfAddr"} + ($crcOffs + $crcSize - $ivtOffs));
    $blocks[1]->{"blkOffs"} = sprintf("0x%08X", $crcOffs + $crcSize);
    $blocks[1]->{"blkSize"} = sprintf("0x%08X", $ivt->{"csfAddr"} - $ivt->{"selfAddr"} - ($crcOffs + $crcSize - $ivtOffs));
    $blocks[1]->{"file"} = "\"$dstImgName\"";
  }
  else
  {
    # so we can sign the whole image in a single chunk
    if($ivt->{"selfAddr"} < $ivt->{"entryAddr"})
    {
      $blocks[0]->{"blkAddr"} = sprintf("0x%08X", $ivt->{"selfAddr"});
      $blocks[0]->{"blkOffs"} = sprintf("0x%08X", $ivtOffs);
      $blocks[0]->{"blkSize"} = sprintf("0x%08X", $ivt->{"csfAddr"} - $ivt->{"selfAddr"});
      $blocks[0]->{"file"} = "\"$dstImgName\"";
    }
    else
    {
      $blocks[0]->{"blkAddr"} = sprintf("0x%08X", $ivt->{"entryAddr"});
      $blocks[0]->{"blkOffs"} = sprintf("0x%08X", $ivtOffs - ($ivt->{"selfAddr"} - $ivt->{"entryAddr"}));
      $blocks[0]->{"blkSize"} = sprintf("0x%08X", $ivt->{"csfAddr"} - $ivt->{"entryAddr"});
      $blocks[0]->{"file"} = "\"$dstImgName\"";
    }
  }
#  printf("ExpSize: 0x%08X\n", $expSize);
#  printf("IvtOffs: 0x%08X\n", $ivtOffs);
#        UID = 0x87, 0x70, 0xFA, 0x5A, 0xB9, 0x6F, 0xE9, 0xBA
#        UID = 0xBA, 0xE9, 0x6F, 0xB9, 0x5A, 0xFA, 0x70, 0x87
#        UID = 0x0A, 0x05, 0x7F, 0x67, 0xD2, 0x21, 0x1D, 0x2C

#      [Unlock]
#        Engine = OCOTP
#        Features = SCS
#        UID = 0x69, 0x29, 0xF8, 0x65, 0xD2, 0x41, 0x4A, 0x28

  if(1 == $srkNonCA)
  {
    ($cstConfig = qq
    {      [Header]
        Version = 4.1
        Hash Algorithm = SHA256
      [Install SRK]
        File = "../crts/$srkTblFileName"
        Source Index = $srkIdx
      [Install NOCAK]
        File = "../crts/$nocaCertFileName"
      [Authenticate CSF]
        Signature Format = CMS
      [Unlock]
        Engine = SNVS
        Features = LP SWR, ZMK WRITE
      [Authenticate Data]
        Verification Index = 0
        Blocks = \\
    }) =~ s/^ {6}//mg;
  }
  else
  {
    ($cstConfig = qq
    {      [Header]
        Version = 4.1
      [Install SRK]
        File = "../crts/$srkTblFileName"
        Source Index = $srkIdx
      [Install CSFK]
        File = "../crts/$csfkCertFileName"
      [Authenticate CSF]
        Signature Format = CMS
      [Unlock]
        Engine = SNVS
        Features = LP SWR, ZMK WRITE
      [Install Key]
        File = "../crts/$imgkCertFileName"
        Verification Index = $srkIdx
        Target Index = $imgkSlot
      [Authenticate Data]
        Verification Index = $imgkSlot
        Blocks = \\
    }) =~ s/^ {6}//mg;
  }

  # Create configuration for CST tool
  print_verbose1($verbose, "\nWrite signing config for storage media...\n");
  print_verbose1($verbose, "  DstPath: %s\n", $dstImgPath.$cstConf);
  open($cstFile, ">", "$dstImgPath"."$cstConf") or die "Failed to open: $!";
  
  # Write the general config
  print($cstFile $cstConfig);
  #print($cstConfig);
  print_verbose1($verbose, "  BlkAddr    BlkOffs    BlkSize    File\n");
  for($i = 0; $i < @blocks; $i++)
  {
    print($cstFile "  ".$blocks[$i]->{"blkAddr"}." ".$blocks[$i]->{"blkOffs"}." ".$blocks[$i]->{"blkSize"}." ".$blocks[$i]->{"file"}."\n");
    print_verbose1($verbose, "  ".$blocks[$i]->{"blkAddr"}." ".$blocks[$i]->{"blkOffs"}." ".$blocks[$i]->{"blkSize"}." ".$blocks[$i]->{"file"}."\n");
  }
  print_verbose1($verbose, "\n");
  close($cstFile);

  
  # RUN the code signing tool (CST)
  signImage();


  # Check if signed image exists
  print_verbose1($verbose, "Check for signature file...\n");
  if(-e $dstImgPath.$csfImgName)
  {
    # Get and print the CSF size
    $csfSize = (-s "$dstImgPath"."$csfImgName");
    print_verbose1($verbose, "  Found signature file.\n");
    print_verbose1($verbose, "  FileName: %s\n", $dstImgPath.$csfImgName);
    print_verbose1($verbose, "  FileSize: 0x%08X (%d Bytes)\n", $csfSize, $csfSize);

    # Open the CSF binary image for read
    open($csfFile, "<", "$dstImgPath"."$csfImgName") or die "Failed to open: $dstImgPath"."$csfImgName $!";
    binmode($csfFile);

    # Read CSF file
    read($csfFile, $buf, $imgSize);
    # Save for later reference
    $csfData = $buf;
    my $csfInfo = {};

#    print_verbose1($verbose, "\nCheck command sequence file (CSF)...\n");
#    hab_parseCsf($csfData, 0, $csfInfo);
  }
  else
  {
    print("Signature file ".$srcImgPath.$srcImgName." doesn't exist.\n");
    exit(-1);
  }

  print_verbose1($verbose, "\nExpanding signature file...\n");
  $expSize = $boot->{"imgSize"} - ($ivt->{"csfAddr"} - $boot->{"startAddr"});
  $padSize = $expSize - $csfSize;
  if($padSize < 0)
  {
    print("\nSignature file doesn't fit into final image\n");
    printf("  ImgSize = 0x%08X (%d Bytes)\n", $boot->{"imgSize"}, $boot->{"imgSize"});
    printf("  CsfOffs = 0x%08X (%d Bytes)\n", ($ivt->{"csfAddr"} - $boot->{"startAddr"}), ($ivt->{"csfAddr"} - $boot->{"startAddr"}));
    printf("  CsfSize = 0x%08X (%d Bytes)\n", $csfSize, $csfSize);
    printf("  ExpSize = 0x%08X (%d Bytes)\n", $expSize, $expSize);
    exit(-1);
  }
  elsif($padSize != 0)
  {
    print_verbose1($verbose, "  ExpSize = 0x%08X (%d Bytes)\n", $expSize, $expSize);
    print_verbose1($verbose, "  PadSize = 0x%08X (%d Bytes)\n", $padSize, $padSize);
    # Fill the padding buffer
    for($i = 0; $i < $padSize; $i++)
    {
      $csfPad .= pack("C", 0x5A);
    }
  }
  else
  {
    print_verbose1($verbose, "  No expansion necessary...\n");
  }


  # Print IVT info
  print_verbose1($verbose, "\nWrite expanded signed image as follows:\n");
  print_verbose1($verbose, "  ImgPath:   %s\n", $srcImgPath.$expImgName);
  print_verbose1($verbose, "\nImage vector table (IVT):\n");
  print_verbose1($verbose, "  Header:    0x%08X (Tag=0x%02X Len=0x%04X (%d Bytes), Ver=0x%02X\n", $ivt->{"header"}, $ivt->{"tag"}, $ivt->{"size"}, $ivt->{"size"}, $ivt->{"ver"});
  print_verbose1($verbose, "  Entry:     0x%08X\n", $ivt->{"entryAddr"});
  print_verbose1($verbose, "  DCD:       0x%08X\n", $ivt->{"dcdAddr"});
  print_verbose1($verbose, "  Boot Data: 0x%08X\n", $ivt->{"bootAddr"});
  print_verbose1($verbose, "  Self:      0x%08X\n", $ivt->{"selfAddr"});
  print_verbose1($verbose, "  CSF:       0x%08X\n", $ivt->{"csfAddr"});

  # Generate IVT
  $ivtData = pack("VVVVVVVV", $ivt->{"header"}, $ivt->{"entryAddr"}, 0, $ivt->{"dcdAddr"}, $ivt->{"bootAddr"}, $ivt->{"selfAddr"}, $ivt->{"csfAddr"}, 0);

  # Print boot data info
  print_verbose1($verbose, "\nBoot data at offset 0x%08X:\n", $bootOffs);
  print_verbose1($verbose, "  Start:     0x%08X\n", $boot->{"startAddr"});
  print_verbose1($verbose, "  Length:    0x%08X (%d Bytes)\n", $boot->{"imgSize"}, $boot->{"imgSize"});
  print_verbose1($verbose, "  Plugin:    0x%08X\n\n", $boot->{"plugin"});

  # Generate boot data
#  $bootData = pack("VVVN", $boot->{"startAddr"}, $boot->{"imgSize"}, $boot->{"plugin"}, 0xAFFEDEAD);
  $bootData = pack("VVV", $boot->{"startAddr"}, $boot->{"imgSize"}, $boot->{"plugin"});

  # Create expanded signed image
  open($expFile, ">", $srcImgPath.$expImgName) or die "Failed to open: ".$srcImgPath.$expImgName." $!";
  binmode($expFile);
  print($expFile $partData);
  print($expFile $ivtData);
  print($expFile $bootData);
  print($expFile $appData);
  print($expFile $appPad);
  print($expFile $csfData);
  print($expFile $csfPad);
  close($expFile);

  makeHex($srcImgPath, $expImgName, $expHexName, $ivt->{"entryAddr"}, $boot->{"startAddr"});
  
  return 0;
}

# This function is called, when the perl script is executed.
genSignCfg(@cmdArgs);

