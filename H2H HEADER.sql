create or replace PACKAGE  XXALM_H2H_BS  


  IS
 
  --    @AUTHOR: NANCY RUBI BRISEÑO SERRANO
  

  --------------------------------------------------------------------------------     
  PROCEDURE readFile ;
  PROCEDURE writeMT940;
  FUNCTION formatAmount (Amount IN VARCHAR2,DIGIT IN VARCHAR2 DEFAULT ',') RETURN VARCHAR2;
  PROCEDURE createReceipts ;
  PROCEDURE getInfoAR(bankAccount IN VARCHAR2, referenceAccount IN VARCHAR2, l_BU OUT VARCHAR2, l_Site OUT VARCHAR2, l_CustAccount OUT VARCHAR2) ;
   PROCEDURE createJob;
  



  END XXALM_H2H_BS;