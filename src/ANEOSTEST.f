      PROGRAM ANEOSTEST
C
C      PROGRAM TO INITIALIZE ANEOS AND CALL IT ONCE
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      PARAMETER (NDENS=0)
      PARAMETER (NTEMP=0)
      DIMENSION IZETL(21)
      COMMON /FILEOS/ KLST, KINP
      COMMON /ANGELX/ W,Y,ALFA,BETA,DADT,DADR,DBDT,ZZ,ET,
     & SN,CVN,EN,PN,PM,EM,SM,CVM,EC,PC,RHO0,RHO00,ZVIB,
     & SMLT,CVMLT,EMLT,PMLT,H1,H2
      COMMON /ANEEL/ TEVX,RHOX,ABARX,ZBARM,T32X,FNX
     &  ,PE,EE,SE,CVE,DPTE,DPRE
     &  ,NMATSX,IIZX
      COMMON /ANEDIS/ GAMMA,PSI,THETA
      PARAMETER (MATBUF=64)
      COMMON /ANESQT/ SQTS(MATBUF),IPSQTS
      DIMENSION RHO(NDENS),TEMP(NTEMP),HISTDENS(100),HISTPRESS(100)
      DIMENSION HISTDPDR(100)
C
      OPEN(10,FILE='ANEOS.INPUT',STATUS='OLD')
      OPEN(12,FILE='ANEOS.OUTPUT')
      TCONV=1.16054D4
C
C     DEFINE ARRAYS OF DENSITY, TEMPERATURE
C
      DO 10 I=1,NDENS
      RHO(I)=10.D0**(1-I)
C      RHO(I)=1.11D0    !REFERENCE DENSITY
  10  CONTINUE
C
      DO 20 J=1,NTEMP
      TEMP(J)=1.D3*DFLOAT(J)/TCONV
C      TEMP(J)=2.008991D-2
  20  CONTINUE
C
C     INITIALIZE ANALYTIC EOS
C
      KLST=12
      KINP=10
      M=0
      IZETL(1)=-1
      CALL ANEOS2 (1,1,0,IZETL)
C
C     CALL ANEOS1 FOR ARRAY OF DENSITY, TEMPERATURE
C
C    INITIAL CALL FOR A SINGLE TEMP, DENSITY
C
C      TEMP1=3.D3/TCONV
C      RHO1=1.D-4
C      CALL ANEOS1 (TEMP1,RHO1,P,E,S,CV,DPDT,DPDR,M)
C
      DEL=1.D-3
      DELTA=1.D0+DEL
      DO 100 I=1,NDENS
      DO 200 J=1,NTEMP
C
C     CALL ANEOS FOR DIRECT CALCULATIONS
C
      IPSQTS=1    
      SQTS(IPSQTS)=DSQRT(TEMP(J))    !square root of temperature for aneos1
      CALL ANEOS1 (TEMP(J),RHO(I),P,E,S,CV,DPDT,DPDR,M)
      W0=W
      Y0=Y
      ZZ0=ZZ
      ZVIB0=ZVIB
      PSI0=PSI
      GAMMA0=GAMMA
      THETA0=THETA
      ALFA0=ALFA
      BETA0=BETA
      DBDT0=DBDT
      DADT0=DADT
      DADR0=DADR
C
C    DEFINE INTERMEDIATE QUANTITIES IN CONSTRUCTING THERMO QUANTITIES
C
      EMFRAC=EM
      ENFRAC=EN
      EEFRAC=EE
      ECFRAC=EC
      PMFRAC=PM
      PNFRAC=PN
      PEFRAC=PE
      PCFRAC=PC
      SMFRAC=SM
      SEFRAC=SE
      SNFRAC=SN
      CVMFRAC=CVM
      CVEFRAC=CVE
      CVNFRAC=CVN
C
C     CALL ANEOS TO COMPUTE DERIVATIVES DIRECTLY
C
      CALL ANEOS1 (TEMP(J),RHO(I)*DELTA,P2,E2,S2,CV2,DPDT2,DPDR2,M)
      ALFA2=ALFA
      ZZ2=ZZ
      SQTS(IPSQTS)=DSQRT(TEMP(J)*DELTA)
      CALL ANEOS1 (TEMP(J)*DELTA,RHO(I),P1,E1,S1,CV1,DPDT1,DPDR1,M)
      ALFA1=ALFA
      BETA1=BETA
      ZZ1=ZZ
C
      ALFAC=-1.5D0*(ZZ2-ZZ0)/(DEL*ZZ0)
      BETAC=(ZZ1-ZZ0)/(DEL*ZZ0)
C
      CVC=(E1-E)/(TEMP(J)*DEL)
      DPDTC=(P1-P)/(TEMP(J)*DEL)
      DPDRC=(P2-P)/(RHO(I)*DEL)
      DBDTC=(BETA1-BETA0)/DEL
      DADTC=(ALFA1-ALFA0)/DEL
      DADRC=(ALFA2-ALFA0)/DEL
C
      DSDR=(S2-S)/(RHO(I)*DEL)
      DPDT=(P1-P)/(TEMP(J)*DEL)
C
C    WRITE OUT RESULTS
C
      WRITE(KLST,1000) RHO(I),TEMP(J)*TCONV
      WRITE(KLST,2000) P,P2,E,E1,S,S2,CV,CVC,DPDT,DPDTC,DPDR,DPDRC
      WRITE(KLST,3000) -DSDR*RHO(I)**2,DPDT
      WRITE(KLST,4000) ZVIB0,Y0,W0,ZZ0,PSI0,GAMMA0,THETA0
      WRITE(KLST,5000) ALFA0, ALFAC,BETA0,BETAC,
     &         DADT0,DADTC,DADR0,DADRC,DBDT0,DBDTC,H1,H2
      WRITE(KLST,9000) ECFRAC,ENFRAC,EMFRAC,EMLT,EEFRAC,
     &                  PCFRAC,PNFRAC,PMFRAC,PMLT,PEFRAC,
     &                         SNFRAC,SMFRAC,SMLT,SEFRAC,
     &                         CVNFRAC,CVMFRAC,CVMLT,CVEFRAC
 200  CONTINUE
 100  CONTINUE
C
C     CALL ANEOS TO CONSTRUCT A TABLE OF THERMODYNAMIC FUNCTIONS AT 1 BAR
C
      PREF=1.D6      !REFERENCE PRESSURE =  1 ATMOSPHERE
      DENS=RHO0      !STARTING GUESS OF DENSITY
      TOL=1.D-7      !PRECISION OF CONVERGENCE TO REF PRESSURE
      WRITE(KLST,6000)
      DO 300 J=1,100
      T=1.D2*DFLOAT(J)/TCONV  !100 DEGREE K STEPS, LIKE JANAF TABLES
      ICOUNT=0
 400  CONTINUE
      CALL ANEOSV (1,T,DENS,1,P,E,S,CV,DPDT,DPDR,FKRO,CS,KPA,
     &  R2PL,R2PH,ZBAR)
      IF (DABS(1.D0-P/PREF).LT.TOL) THEN
        GOTO 250
      ELSE
        ICOUNT=ICOUNT+1
        HISTDENS(ICOUNT)=DENS
        HISTPRESS(ICOUNT)=P
        HISTDPDR(ICOUNT)=DPDR
        IF(ICOUNT.GT.100) THEN
          WRITE(KLST,*) 'ITERATION FAILED FOR T = ',T*TCONV
	    WRITE(KLST,8700)
	    DO 201 K=1,50
	      WRITE(KLST,8900) K,HISTDENS(K),HISTPRESS(K),HISTDPDR(K)
 201        CONTINUE
	    GOTO 300
	  ENDIF
	  DENSOLD=DENS
        DENS=DENS-(P-PREF)/DPDR          !I need to improve this for dpdr = 0!
	  IF(DENS.LT.0.D0) DENS=0.5*DENSOLD  !NEWTON FAILS AT VAPORIZATION TEMP
	  GOTO 400
      ENDIF
  250 CONTINUE
      HSI=(E+P/DENS)*1.D-4    !ENTHALPY IN SI UNITS
      GSI=HSI-T*S*1.D-4       !GIBBS ENERGY IN SI UNITS
      WRITE(KLST,8000) T*TCONV,DENS*1.D3,P*1.D-10,E*1.D-4,HSI,
     & S*(1.D-4/TCONV),GSI,KPA,ICOUNT
  300 CONTINUE
C
C    CALL ANEOS TO COMPUTE AND PRINT THE COLD PRESSURE FOR A RANGE OF DENSITY
C
      DENS0=RHO00    !REFERENCE DENSITY AT ZERO TEMPERATURE
      NDENSIT=100
      DMIN=5.D-2
      DMAX=5.0D0
      DINC=(DMAX-DMIN)/DFLOAT(NDENSIT-1)
      WRITE(KLST,8300)
      DO 500 J=1,NDENSIT
      DENS=DMIN+DINC*DFLOAT(J-1)
      ETA=DENS/DENS0
      CALL ANEOS1 (1.D-6,DENS,P,E,S,CV,DPDT,DPDR,M)
      GCOLD=E+P/DENS
      WRITE(KLST,8500) DENS,P,E,GCOLD,DPDR,ETA
500   CONTINUE
      STOP
C
1000  FORMAT(///'DENSITY = ',1PE15.5,'  TEMP(K) = ',1PE15.5//)
2000  FORMAT('  ANALYTIC COMPUTATIONAL RESULTS FROM ANEOS1'// 
     &'       PRESSURE = ',1PE15.5,'   AT RHO+DELTA RHO  = ',1PE15.5/
     &'       ENERGY   = ',1PE15.5,'   AT T+DELTA T      = ',1PE15.5/
     &'       ENTROPY  = ',1PE15.5,'   AT RHO+DELTA RHO  = ',1PE15.5/
     &'       HEAT CAP = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       DPDT     = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       DPDR     = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5)
3000  FORMAT(//'  TEST OF SECOND DERIVATIVES--THESE SHOULD BE EQUAL'// 
     &'       -DSDR*RHO**2 = ',1PE15.5/   
     &'        DPDT        = ',1PE15.5)
4000  FORMAT(//'  BOUND STATE AND EOS FACTORS'//
     &'       ZVIB FUNC = ',1PE15.5/
     &'       FACTOR Y  = ',1PE15.5/
     &'       UNBOUND W = ',1PE15.5/
     &'       RENORM Z  = ',1PE15.5/
     &'       PSI       = ',1PE15.5/
     &'       GAMMA     = ',1PE15.5/
     &'       THETA     = ',1PE15.5/)
5000  FORMAT(//'  INTERMEDIATE QUANTITIES FOR MOLECULAR COMPUTATION'//
     &'       ALPHA     = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       BETA      = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       DADT      = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       DADR      = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       DBDT      = ',1PE15.5,'   APPROX DERIVATIVE = ',1PE15.5/
     &'       H1        = ',1PE15.5/
     &'       H2        = ',1PE15.5)
6000  FORMAT(//' THERMODYNAMIC FUNCTIONS OF TEMPERATURE AT 1 BAR,'//
     & '        TEMP         DENSITY       PRESSURE       ENERGY',
     & '         ENTHALPY        ENTROPY        GIBBS       PHASE',
     & '     #ITER'/
     & '         K           kg/m**3         GPa            J/kg',
     & '           J/kg           J/kg-K         J/kg'/)
7000  FORMAT(//' PRESSURE ITERATION FAILS TO CONVERGE AFTER ',
     & I5,' STEPS'//)
8000  FORMAT(7(1PE15.5),5X,I2,5X,I5)
8300  FORMAT(//' COLD PRESSURE DEPENDENCE ON DENSITY, CGS UNITS'//
     &'       DENSITY       PRESSURE       ENERGY         GIBBS',
     &'           DPDR           ETA'/)
8500  FORMAT(6(1PE15.5))
8700  FORMAT(/'ITERATION HISTORY:'/' STEP#    DENSITY      PRESSURE   ',
     &'   DPDR'/)
8900  FORMAT(I5,3(1PE15.5))
9000  FORMAT(//' INDIVIDUAL CONTRIBUTIONS TO THERMODYNAMIC FUNCTIONS:'//
     &'  QUANTITY         COLD          NUCLEAR      MOLECULAR',
     &'         MELT        ELECTRONIC'//
     &'   ENERGY   ',5(1PE15.5)/
     &'   PRESSURE ',5(1PE15.5)/
     &'   ENTROPY  ',15X,4(1PE15.5)/
     &'   HEAT CAP.',15X,4(1PE15.5))
C
      END
