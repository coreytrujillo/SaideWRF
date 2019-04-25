Module module_add_emiss_burn
CONTAINS
       subroutine add_emis_burn(id,dtstep,ktau,dz8w,rho_phy,chem,       &
            julday,gmt,xlat,xlong,t_phy,p_phy,                          &
            ebu,chem_opt,tracer_opt,biomass_burn_opt,                   &
            num_c,ids,ide, jds,jde, kds,kde,                            &
            ims,ime, jms,jme, kms,kme,                                  &
            its,ite, jts,jte, kts,kte                                   )
  USE module_configure, only: grid_config_rec_type
  USE module_state_description
  IMPLICIT NONE


!  TYPE(grid_config_rec_type),  INTENT(IN   )    :: config_flags

   INTEGER,      INTENT(IN   ) :: id,julday,chem_opt,biomass_burn_opt,     &
                                  num_c,ids,ide, jds,jde, kds,kde,      &
                                  ims,ime, jms,jme, kms,kme,               &
                                  its,ite, jts,jte, kts,kte,tracer_opt
   INTEGER,      INTENT(IN   ) ::                                          &
                                  ktau
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme, num_c ),                 &
         INTENT(INOUT ) ::                                   chem
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme, num_ebu ),                 &
         INTENT(IN    ) ::                           ebu
!
!
!
   REAL,  DIMENSION( ims:ime ,  jms:jme )         ,               &
          INTENT(IN   ) ::                                                 &
                                                      xlat,xlong
   REAL,  DIMENSION( ims:ime , kms:kme , jms:jme )         ,               &
          INTENT(IN   ) ::                                                 &
                                                      t_phy,               &
                                                      p_phy,               &
                                                      dz8w,                &
                                                    rho_phy

      REAL,      INTENT(IN   ) ::                                          &
                             dtstep,gmt
    integer ::imonth1,idate1,iyear1,itime1
    integer :: i,j,k
    real :: time,conv_rho
    integer :: iweek,idays
    real :: tign,timeq,r_q,r_antro
    real, dimension(7) :: week_CYCLE
    !                     dia da semana:  DOM   SEG   TER   QUA   QUI   SEX   SAB
    !                            iweek=   1     2     3     4     5     6     7
    !- dados cetesb/campinas/2005
    data (week_CYCLE(iweek),iweek=1,7) /0.67, 1.1, 1.1, 1.1, 1.1, 1.1, 0.83/ !total = 7
    real, parameter :: bx_bburn  = 18.041288 * 3600., & !- peak at 18 UTC
                  cx        =  2.184936 * 3600., &
                  rinti     =  2.1813936e-8    , &
                  ax        = 2000.6038        , &
                  bx_antro  = 15.041288 * 3600.    !- peak em 15 UTC
    !itime1 : initial time of simulation (hour*100)
    ! time  : time elapsed in seconds
    ! r_q : gaussian function in 1/sec

    !-------------biomass burning diurnal cycle --------------------
    !number of days of simulation
    itime1=0
    time=0.
    idays = int(( float(itime1)/100. + time/3600.)/24.+.00001)
    tign  = real(idays)*24.*3600.
    ! Modulacao da queimada media durante o ciclo diurno(unidade: 1/s)
    ! com a int( r_q dt) (0 - 24h)= 1.
    timeq= ( time + float(itime1)*0.01*3600. - tign )
    timeq=gmt*3600.+float(ktau)*dtstep
    timeq=mod(timeq,86400.)
    r_q  = rinti*( ax * exp( -(timeq-bx_bburn)**2/(2.*cx**2) ) + 100. -  &
           5.6712963e-4*( timeq ))


    !------------- anthropogenic diurnal cycle (industrial,residencial, ...)
    ! weekly cycle
    ! week day
    iweek= int(((float(julday)/7. - &
           int(julday/7))*7.)) + 1
    if(iweek.gt.7) iweek = iweek-7
    !- weekly + diurnal cycle
    r_q=r_q*86400.
    r_q=1. ! no diurnal cycle
!
!tracer_opt has to come in as zero, if chem_opt is not =0!
      temiss_select:  SELECT CASE(tracer_opt)
         CASE (TRACER_SMOKE)
!
! for smoke only
!
          do j=jts,jte
          do i=its,ite
          do k=kts,kte
             conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
             chem(i,k,j,p_smoke)  =  chem(i,k,j,p_smoke)+ebu(i,k,j,p_ebu_co)*conv_rho
          enddo
          enddo
          enddo
         CASE (TRACER_TEST2)
          do j=jts,jte
          do i=its,ite
          do k=kts,kte
             conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
             chem(i,k,j,p_tr17_3)  =  chem(i,k,j,p_tr17_3)+ebu(i,k,j,p_ebu_co)*conv_rho
             chem(i,k,j,p_tr17_4)  =  chem(i,k,j,p_tr17_4)+ebu(i,k,j,p_ebu_co)*conv_rho
          enddo
          enddo
          enddo
         CASE (TRACER_TEST7)
          do j=jts,jte
          do i=its,ite
          do k=kts,kte
             conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
             chem(i,k,j,p_smoke)  = chem(i,k,j,p_smoke)+ebu(i,k,j,p_ebu_co)*conv_rho
             chem(i,k,j,p_tr17_1)  =  chem(i,k,j,p_tr17_1)+ebu(i,k,j,p_ebu_co_1)*conv_rho
             chem(i,k,j,p_tr17_2)  =  chem(i,k,j,p_tr17_2)+ebu(i,k,j,p_ebu_co_2)*conv_rho
             chem(i,k,j,p_tr17_3)  =  chem(i,k,j,p_tr17_3)+ebu(i,k,j,p_ebu_co_3)*conv_rho
             chem(i,k,j,p_tr17_4)  =  chem(i,k,j,p_tr17_4)+ebu(i,k,j,p_ebu_co_4)*conv_rho
             chem(i,k,j,p_tr17_5)  =  chem(i,k,j,p_tr17_5)+ebu(i,k,j,p_ebu_co_5)*conv_rho
             chem(i,k,j,p_tr17_6)  =  chem(i,k,j,p_tr17_6)+ebu(i,k,j,p_ebu_co_6)*conv_rho
             chem(i,k,j,p_tr17_7)  =  chem(i,k,j,p_tr17_7)+ebu(i,k,j,p_ebu_co_7)*conv_rho
             chem(i,k,j,p_tr17_8)  =  chem(i,k,j,p_tr17_8)+ebu(i,k,j,p_ebu_co_8)*conv_rho
             chem(i,k,j,p_tr17_9)  =  chem(i,k,j,p_tr17_9)+ebu(i,k,j,p_ebu_co_9)*conv_rho
             chem(i,k,j,p_tr17_10)  =  chem(i,k,j,p_tr17_10)+ebu(i,k,j,p_ebu_co_10)*conv_rho
             chem(i,k,j,p_tr17_11)  =  chem(i,k,j,p_tr17_11)+ebu(i,k,j,p_ebu_co_11)*conv_rho
             chem(i,k,j,p_tr17_12)  =  chem(i,k,j,p_tr17_12)+ebu(i,k,j,p_ebu_co_12)*conv_rho
             chem(i,k,j,p_tr17_13)  =  chem(i,k,j,p_tr17_13)+ebu(i,k,j,p_ebu_co_13)*conv_rho
             chem(i,k,j,p_tr17_14)  =  chem(i,k,j,p_tr17_14)+ebu(i,k,j,p_ebu_co_14)*conv_rho
             chem(i,k,j,p_tr17_15)  =  chem(i,k,j,p_tr17_15)+ebu(i,k,j,p_ebu_co_15)*conv_rho
             chem(i,k,j,p_tr17_16)  =  chem(i,k,j,p_tr17_16)+ebu(i,k,j,p_ebu_co_16)*conv_rho
             chem(i,k,j,p_tr17_17)  =  chem(i,k,j,p_tr17_17)+ebu(i,k,j,p_ebu_co_17)*conv_rho
             chem(i,k,j,p_tr17_18)  =  chem(i,k,j,p_tr17_18)+ebu(i,k,j,p_ebu_co_18)*conv_rho
             chem(i,k,j,p_tr17_19)  =  chem(i,k,j,p_tr17_19)+ebu(i,k,j,p_ebu_co_19)*conv_rho
             chem(i,k,j,p_tr17_20)  =  chem(i,k,j,p_tr17_20)+ebu(i,k,j,p_ebu_co_20)*conv_rho
             chem(i,k,j,p_tr17_21)  =  chem(i,k,j,p_tr17_21)+ebu(i,k,j,p_ebu_co_21)*conv_rho
             chem(i,k,j,p_tr17_22)  =  chem(i,k,j,p_tr17_22)+ebu(i,k,j,p_ebu_co_22)*conv_rho
             chem(i,k,j,p_tr17_23)  =  chem(i,k,j,p_tr17_23)+ebu(i,k,j,p_ebu_co_23)*conv_rho
             chem(i,k,j,p_tr17_24)  =  chem(i,k,j,p_tr17_24)+ebu(i,k,j,p_ebu_co_24)*conv_rho
             chem(i,k,j,p_tr17_25)  =  chem(i,k,j,p_tr17_25)+ebu(i,k,j,p_ebu_co_25)*conv_rho
             chem(i,k,j,p_tr17_26)  =  chem(i,k,j,p_tr17_26)+ebu(i,k,j,p_ebu_co_26)*conv_rho
             chem(i,k,j,p_tr17_27)  =  chem(i,k,j,p_tr17_27)+ebu(i,k,j,p_ebu_co_27)*conv_rho
             chem(i,k,j,p_tr17_28)  =  chem(i,k,j,p_tr17_28)+ebu(i,k,j,p_ebu_co_28)*conv_rho
             chem(i,k,j,p_tr17_29)  =  chem(i,k,j,p_tr17_29)+ebu(i,k,j,p_ebu_co_29)*conv_rho
             chem(i,k,j,p_tr17_30)  =  chem(i,k,j,p_tr17_30)+ebu(i,k,j,p_ebu_co_30)*conv_rho
             chem(i,k,j,p_tr17_31)  =  chem(i,k,j,p_tr17_31)+ebu(i,k,j,p_ebu_co_31)*conv_rho
             chem(i,k,j,p_tr17_32)  =  chem(i,k,j,p_tr17_32)+ebu(i,k,j,p_ebu_co_32)*conv_rho
             chem(i,k,j,p_tr17_33)  =  chem(i,k,j,p_tr17_33)+ebu(i,k,j,p_ebu_co_33)*conv_rho
             chem(i,k,j,p_tr17_34)  =  chem(i,k,j,p_tr17_34)+ebu(i,k,j,p_ebu_co_34)*conv_rho
             chem(i,k,j,p_tr17_35)  =  chem(i,k,j,p_tr17_35)+ebu(i,k,j,p_ebu_co_35)*conv_rho
             chem(i,k,j,p_tr17_36)  =  chem(i,k,j,p_tr17_36)+ebu(i,k,j,p_ebu_co_36)*conv_rho
             chem(i,k,j,p_tr17_37)  =  chem(i,k,j,p_tr17_37)+ebu(i,k,j,p_ebu_co_37)*conv_rho
             chem(i,k,j,p_tr17_38)  =  chem(i,k,j,p_tr17_38)+ebu(i,k,j,p_ebu_co_38)*conv_rho
             chem(i,k,j,p_tr17_39)  =  chem(i,k,j,p_tr17_39)+ebu(i,k,j,p_ebu_co_39)*conv_rho
             chem(i,k,j,p_tr17_40)  =  chem(i,k,j,p_tr17_40)+ebu(i,k,j,p_ebu_co_40)*conv_rho
             chem(i,k,j,p_tr17_41)  =  chem(i,k,j,p_tr17_41)+ebu(i,k,j,p_ebu_co_41)*conv_rho
             chem(i,k,j,p_tr17_42)  =  chem(i,k,j,p_tr17_42)+ebu(i,k,j,p_ebu_co_42)*conv_rho
             chem(i,k,j,p_tr17_43)  =  chem(i,k,j,p_tr17_43)+ebu(i,k,j,p_ebu_co_43)*conv_rho
             chem(i,k,j,p_tr17_44)  =  chem(i,k,j,p_tr17_44)+ebu(i,k,j,p_ebu_co_44)*conv_rho
             chem(i,k,j,p_tr17_45)  =  chem(i,k,j,p_tr17_45)+ebu(i,k,j,p_ebu_co_45)*conv_rho
             chem(i,k,j,p_tr17_46)  =  chem(i,k,j,p_tr17_46)+ebu(i,k,j,p_ebu_co_46)*conv_rho
             chem(i,k,j,p_tr17_47)  =  chem(i,k,j,p_tr17_47)+ebu(i,k,j,p_ebu_co_47)*conv_rho
             chem(i,k,j,p_tr17_48)  =  chem(i,k,j,p_tr17_48)+ebu(i,k,j,p_ebu_co_48)*conv_rho
             chem(i,k,j,p_tr17_49)  =  chem(i,k,j,p_tr17_49)+ebu(i,k,j,p_ebu_co_49)*conv_rho
             chem(i,k,j,p_tr17_50)  =  chem(i,k,j,p_tr17_50)+ebu(i,k,j,p_ebu_co_50)*conv_rho
             chem(i,k,j,p_tr17_51)  =  chem(i,k,j,p_tr17_51)+ebu(i,k,j,p_ebu_co_51)*conv_rho
             chem(i,k,j,p_tr17_52)  =  chem(i,k,j,p_tr17_52)+ebu(i,k,j,p_ebu_co_52)*conv_rho
             chem(i,k,j,p_tr17_53)  =  chem(i,k,j,p_tr17_53)+ebu(i,k,j,p_ebu_co_53)*conv_rho
             chem(i,k,j,p_tr17_54)  =  chem(i,k,j,p_tr17_54)+ebu(i,k,j,p_ebu_co_54)*conv_rho
             chem(i,k,j,p_tr17_55)  =  chem(i,k,j,p_tr17_55)+ebu(i,k,j,p_ebu_co_55)*conv_rho
             chem(i,k,j,p_tr17_56)  =  chem(i,k,j,p_tr17_56)+ebu(i,k,j,p_ebu_co_56)*conv_rho
             chem(i,k,j,p_tr17_57)  =  chem(i,k,j,p_tr17_57)+ebu(i,k,j,p_ebu_co_57)*conv_rho
             chem(i,k,j,p_tr17_58)  =  chem(i,k,j,p_tr17_58)+ebu(i,k,j,p_ebu_co_58)*conv_rho
             chem(i,k,j,p_tr17_59)  =  chem(i,k,j,p_tr17_59)+ebu(i,k,j,p_ebu_co_59)*conv_rho
             chem(i,k,j,p_tr17_60)  =  chem(i,k,j,p_tr17_60)+ebu(i,k,j,p_ebu_co_60)*conv_rho
             chem(i,k,j,p_tr17_61)  =  chem(i,k,j,p_tr17_61)+ebu(i,k,j,p_ebu_co_61)*conv_rho
             chem(i,k,j,p_tr17_62)  =  chem(i,k,j,p_tr17_62)+ebu(i,k,j,p_ebu_co_62)*conv_rho
             chem(i,k,j,p_tr17_63)  =  chem(i,k,j,p_tr17_63)+ebu(i,k,j,p_ebu_co_63)*conv_rho
             chem(i,k,j,p_tr17_64)  =  chem(i,k,j,p_tr17_64)+ebu(i,k,j,p_ebu_co_64)*conv_rho
             chem(i,k,j,p_tr17_65)  =  chem(i,k,j,p_tr17_65)+ebu(i,k,j,p_ebu_co_65)*conv_rho
             chem(i,k,j,p_tr17_66)  =  chem(i,k,j,p_tr17_66)+ebu(i,k,j,p_ebu_co_66)*conv_rho
             chem(i,k,j,p_tr17_67)  =  chem(i,k,j,p_tr17_67)+ebu(i,k,j,p_ebu_co_67)*conv_rho
             chem(i,k,j,p_tr17_68)  =  chem(i,k,j,p_tr17_68)+ebu(i,k,j,p_ebu_co_68)*conv_rho
          enddo
          enddo
          enddo
         CASE DEFAULT
             call wrf_debug(15,'nothing done with burn emissions for tracers here')
      END SELECT temiss_select
      emiss_select:  SELECT CASE(chem_opt)
      CASE (RACMPM_KPP)
          do j=jts,jte
          do i=its,ite
           do k=kts,kte
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
        chem(i,k,j,p_so2)  =  chem(i,k,j,p_so2)                        &
                         +ebu(i,k,j,p_ebu_so2)*conv_rho
        chem(i,k,j,p_sulf)  =  chem(i,k,j,p_sulf)                        &
                         +ebu(i,k,j,p_ebu_sulf)*conv_rho
        chem(i,k,j,p_csl)  =  chem(i,k,j,p_csl)                        &
                         +ebu(i,k,j,p_ebu_csl)*conv_rho
        chem(i,k,j,p_iso)  = chem(i,k,j,p_iso)                         &
                         +ebu(i,k,j,p_ebu_iso)*conv_rho
        chem(i,k,j,p_no)   = chem(i,k,j,p_no)                          &
                         +ebu(i,k,j,p_ebu_no)*conv_rho
        chem(i,k,j,p_no2)  = chem(i,k,j,p_no2)                         &
                         +ebu(i,k,j,p_ebu_no2)*conv_rho
        chem(i,k,j,p_ald)  = chem(i,k,j,p_ald)                         &
                         +ebu(i,k,j,p_ebu_ald)*conv_rho
        chem(i,k,j,p_hcho) = chem(i,k,j,p_hcho)                        &
                         +ebu(i,k,j,p_ebu_hcho)*conv_rho
        chem(i,k,j,p_ora2)  = chem(i,k,j,p_ora2)                       &
                         +ebu(i,k,j,p_ebu_ora2)*conv_rho
        chem(i,k,j,p_hc3)  = chem(i,k,j,p_hc3)                         &
                         +ebu(i,k,j,p_ebu_hc3)*conv_rho
        chem(i,k,j,p_hc5)  = chem(i,k,j,p_hc5)                         &
                         +ebu(i,k,j,p_ebu_hc5)*conv_rho
        chem(i,k,j,p_hc8)  = chem(i,k,j,p_hc8)                         &
                         +ebu(i,k,j,p_ebu_hc8)*conv_rho
        chem(i,k,j,p_eth)  = chem(i,k,j,p_eth)                         &
                         +ebu(i,k,j,p_ebu_eth)*conv_rho
        chem(i,k,j,p_co)  = chem(i,k,j,p_co)                           &
                         +ebu(i,k,j,p_ebu_co)*conv_rho
        chem(i,k,j,p_olt)  = chem(i,k,j,p_olt)                         &
                         +ebu(i,k,j,p_ebu_olt)*conv_rho
        chem(i,k,j,p_oli)  = chem(i,k,j,p_oli)                         &
                         +ebu(i,k,j,p_ebu_oli)*conv_rho
        chem(i,k,j,p_tol)  = chem(i,k,j,p_tol)                         &
                         +ebu(i,k,j,p_ebu_tol)*conv_rho
        chem(i,k,j,p_xyl)  = chem(i,k,j,p_xyl)                         &
                         +ebu(i,k,j,p_ebu_xyl)*conv_rho
        chem(i,k,j,p_ket)  =  chem(i,k,j,p_ket)                        &
                         +ebu(i,k,j,p_ebu_ket)*conv_rho
        chem(i,k,j,p_pm_25)  =  chem(i,k,j,p_pm_25)                        &
                         +r_q*ebu(i,k,j,p_ebu_pm25)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_pm_10)  =  chem(i,k,j,p_pm_10)                        &
                         +r_q*ebu(i,k,j,p_ebu_pm10)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        enddo
        enddo
        enddo
      CASE (RADM2SORG,RACMSORG_KPP, RADM2SORG_KPP, RACM_ESRLSORG_KPP, RACM_SOA_VBS_KPP,  &
            RADM2SORG_AQ, RADM2SORG_AQCHEM, RACMSORG_AQ, RACMSORG_AQCHEM_KPP,RACM_ESRLSORG_AQCHEM_KPP)
          do j=jts,jte
          do i=its,ite
           do k=kts,kte
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/60./dz8w(i,k,j)

        chem(i,k,j,p_so2)  =  chem(i,k,j,p_so2)                        &
                         +ebu(i,k,j,p_ebu_so2)*conv_rho
        chem(i,k,j,p_sulf)  =  chem(i,k,j,p_sulf)                        &
                         +ebu(i,k,j,p_ebu_sulf)*conv_rho
        chem(i,k,j,p_csl)  =  chem(i,k,j,p_csl)                        &
                         +ebu(i,k,j,p_ebu_csl)*conv_rho
        chem(i,k,j,p_iso)  = chem(i,k,j,p_iso)                         &
                         +ebu(i,k,j,p_ebu_iso)*conv_rho
        chem(i,k,j,p_no)   = chem(i,k,j,p_no)                          &
                         +ebu(i,k,j,p_ebu_no)*conv_rho
        chem(i,k,j,p_no2)  = chem(i,k,j,p_no2)                         &
                         +ebu(i,k,j,p_ebu_no2)*conv_rho
        chem(i,k,j,p_ald)  = chem(i,k,j,p_ald)                         &
                         +ebu(i,k,j,p_ebu_ald)*conv_rho
        chem(i,k,j,p_hcho) = chem(i,k,j,p_hcho)                        &
                         +ebu(i,k,j,p_ebu_hcho)*conv_rho
        chem(i,k,j,p_ora2)  = chem(i,k,j,p_ora2)                       &
                         +ebu(i,k,j,p_ebu_ora2)*conv_rho
        chem(i,k,j,p_hc3)  = chem(i,k,j,p_hc3)                         &
                         +ebu(i,k,j,p_ebu_hc3)*conv_rho
        chem(i,k,j,p_hc5)  = chem(i,k,j,p_hc5)                         &
                         +ebu(i,k,j,p_ebu_hc5)*conv_rho
        chem(i,k,j,p_hc8)  = chem(i,k,j,p_hc8)                         &
                         +ebu(i,k,j,p_ebu_hc8)*conv_rho
        chem(i,k,j,p_eth)  = chem(i,k,j,p_eth)                         &
                         +ebu(i,k,j,p_ebu_eth)*conv_rho
        chem(i,k,j,p_co)  = chem(i,k,j,p_co)                           &
                         +ebu(i,k,j,p_ebu_co)*conv_rho
        chem(i,k,j,p_olt)  = chem(i,k,j,p_olt)                         &
                         +ebu(i,k,j,p_ebu_olt)*conv_rho
        chem(i,k,j,p_oli)  = chem(i,k,j,p_oli)                         &
                         +ebu(i,k,j,p_ebu_oli)*conv_rho
        chem(i,k,j,p_tol)  = chem(i,k,j,p_tol)                         &
                         +ebu(i,k,j,p_ebu_tol)*conv_rho
        chem(i,k,j,p_xyl)  = chem(i,k,j,p_xyl)                         &
                         +ebu(i,k,j,p_ebu_xyl)*conv_rho
        chem(i,k,j,p_ket)  =  chem(i,k,j,p_ket)                        &
                         +ebu(i,k,j,p_ebu_ket)*conv_rho
        enddo
        enddo
        enddo
      CASE (GOCART_SIMPLE)
          do j=jts,jte
          do i=its,ite
          do k=kts,kte
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
        chem(i,k,j,p_so2)  =  chem(i,k,j,p_so2)                        &
                         +ebu(i,k,j,p_ebu_so2)*conv_rho
        chem(i,k,j,p_sulf)  =  chem(i,k,j,p_sulf)                        &
                         +ebu(i,k,j,p_ebu_sulf)*conv_rho
        chem(i,k,j,p_dms)  =  chem(i,k,j,p_dms)                        &
                         +ebu(i,k,j,p_ebu_dms)*conv_rho
        chem(i,k,j,p_oc1)  =  chem(i,k,j,p_oc1)                        &
                         +r_q*ebu(i,k,j,p_ebu_oc)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_bc1)  =  chem(i,k,j,p_bc1)                        &
                         +r_q*ebu(i,k,j,p_ebu_bc)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_p25)  =  chem(i,k,j,p_p25)                        &
                         +r_q*ebu(i,k,j,p_ebu_pm25)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_p10)  =  chem(i,k,j,p_p10)                        &
                         +r_q*ebu(i,k,j,p_ebu_pm10)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        enddo
        enddo
        enddo
      CASE (GOCARTRACM_KPP,GOCARTRADM2_KPP,GOCARTRADM2)
          do j=jts,jte
          do i=its,ite
           do k=kts,kte
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
        chem(i,k,j,p_so2)  =  chem(i,k,j,p_so2)                        &
                         +ebu(i,k,j,p_ebu_so2)*conv_rho
        chem(i,k,j,p_sulf)  =  chem(i,k,j,p_sulf)                        &
                         +ebu(i,k,j,p_ebu_sulf)*conv_rho
        chem(i,k,j,p_dms)  =  chem(i,k,j,p_dms)                        &
                         +ebu(i,k,j,p_ebu_dms)*conv_rho
        chem(i,k,j,p_csl)  =  chem(i,k,j,p_csl)                        &
                         +ebu(i,k,j,p_ebu_csl)*conv_rho
        chem(i,k,j,p_iso)  = chem(i,k,j,p_iso)                         &
                         +ebu(i,k,j,p_ebu_iso)*conv_rho
        chem(i,k,j,p_no)   = chem(i,k,j,p_no)                          &
                         +ebu(i,k,j,p_ebu_no)*conv_rho
        chem(i,k,j,p_no2)  = chem(i,k,j,p_no2)                         &
                         +ebu(i,k,j,p_ebu_no2)*conv_rho
        chem(i,k,j,p_ald)  = chem(i,k,j,p_ald)                         &
                         +ebu(i,k,j,p_ebu_ald)*conv_rho
        chem(i,k,j,p_hcho) = chem(i,k,j,p_hcho)                        &
                         +ebu(i,k,j,p_ebu_hcho)*conv_rho
        chem(i,k,j,p_ora2)  = chem(i,k,j,p_ora2)                       &
                         +ebu(i,k,j,p_ebu_ora2)*conv_rho
        chem(i,k,j,p_hc3)  = chem(i,k,j,p_hc3)                         &
                         +ebu(i,k,j,p_ebu_hc3)*conv_rho
        chem(i,k,j,p_hc5)  = chem(i,k,j,p_hc5)                         &
                         +ebu(i,k,j,p_ebu_hc5)*conv_rho
        chem(i,k,j,p_hc8)  = chem(i,k,j,p_hc8)                         &
                         +ebu(i,k,j,p_ebu_hc8)*conv_rho
        chem(i,k,j,p_eth)  = chem(i,k,j,p_eth)                         &
                         +ebu(i,k,j,p_ebu_eth)*conv_rho
        chem(i,k,j,p_co)  = chem(i,k,j,p_co)                           &
                         +ebu(i,k,j,p_ebu_co)*conv_rho
        chem(i,k,j,p_olt)  = chem(i,k,j,p_olt)                         &
                         +ebu(i,k,j,p_ebu_olt)*conv_rho
        chem(i,k,j,p_oli)  = chem(i,k,j,p_oli)                         &
                         +ebu(i,k,j,p_ebu_oli)*conv_rho
        chem(i,k,j,p_tol)  = chem(i,k,j,p_tol)                         &
                         +ebu(i,k,j,p_ebu_tol)*conv_rho
        chem(i,k,j,p_xyl)  = chem(i,k,j,p_xyl)                         &
                         +ebu(i,k,j,p_ebu_xyl)*conv_rho
        chem(i,k,j,p_ket)  =  chem(i,k,j,p_ket)                        &
                         +ebu(i,k,j,p_ebu_ket)*conv_rho
        chem(i,k,j,p_oc1)  =  chem(i,k,j,p_oc1)                        &
                         +r_q*ebu(i,k,j,p_ebu_oc)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_bc1)  =  chem(i,k,j,p_bc1)                        &
                         +r_q*ebu(i,k,j,p_ebu_bc)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_p25)  =  chem(i,k,j,p_p25)                        &
                         +r_q*ebu(i,k,j,p_ebu_pm25)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        chem(i,k,j,p_p10)  =  chem(i,k,j,p_p10)                        &
                         +r_q*ebu(i,k,j,p_ebu_pm10)/rho_phy(i,k,j)*dtstep/dz8w(i,k,j)
        enddo
        enddo
        enddo
      CASE (RADM2,RACM_KPP,RACM_MIM_KPP,SAPRC99_KPP,SAPRC99_MOSAIC_4BIN_VBS2_KPP)
          do j=jts,jte
          do i=its,ite
           do k=kts,kte
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/60./dz8w(i,k,j)
        chem(i,k,j,p_csl)  =  chem(i,k,j,p_csl)                        &
                         +ebu(i,k,j,p_ebu_csl)*conv_rho
        chem(i,k,j,p_iso)  = chem(i,k,j,p_iso)                         &
                         +ebu(i,k,j,p_ebu_iso)*conv_rho
        chem(i,k,j,p_no)   = chem(i,k,j,p_no)                          &
                         +ebu(i,k,j,p_ebu_no)*conv_rho
        chem(i,k,j,p_no2)  = chem(i,k,j,p_no2)                         &
                         +ebu(i,k,j,p_ebu_no2)*conv_rho
        chem(i,k,j,p_ald)  = chem(i,k,j,p_ald)                         &
                         +ebu(i,k,j,p_ebu_ald)*conv_rho
        chem(i,k,j,p_hcho) = chem(i,k,j,p_hcho)                        &
                         +ebu(i,k,j,p_ebu_hcho)*conv_rho
        chem(i,k,j,p_ora2)  = chem(i,k,j,p_ora2)                       &
                         +ebu(i,k,j,p_ebu_ora2)*conv_rho
        chem(i,k,j,p_hc3)  = chem(i,k,j,p_hc3)                         &
                         +ebu(i,k,j,p_ebu_hc3)*conv_rho
        chem(i,k,j,p_hc5)  = chem(i,k,j,p_hc5)                         &
                         +ebu(i,k,j,p_ebu_hc5)*conv_rho
        chem(i,k,j,p_hc8)  = chem(i,k,j,p_hc8)                         &
                         +ebu(i,k,j,p_ebu_hc8)*conv_rho
        chem(i,k,j,p_eth)  = chem(i,k,j,p_eth)                         &
                         +ebu(i,k,j,p_ebu_eth)*conv_rho
        chem(i,k,j,p_co)  = chem(i,k,j,p_co)                           &
                         +ebu(i,k,j,p_ebu_co)*conv_rho
        chem(i,k,j,p_olt)  = chem(i,k,j,p_olt)                         &
                         +ebu(i,k,j,p_ebu_olt)*conv_rho
        chem(i,k,j,p_oli)  = chem(i,k,j,p_oli)                         &
                         +ebu(i,k,j,p_ebu_oli)*conv_rho
        chem(i,k,j,p_tol)  = chem(i,k,j,p_tol)                         &
                         +ebu(i,k,j,p_ebu_tol)*conv_rho
        chem(i,k,j,p_xyl)  = chem(i,k,j,p_xyl)                         &
                         +ebu(i,k,j,p_ebu_xyl)*conv_rho
        chem(i,k,j,p_ket)  =  chem(i,k,j,p_ket)                        &
                         +ebu(i,k,j,p_ebu_ket)*conv_rho
        enddo
        enddo
        enddo
      CASE (MOZART_KPP,MOZCART_KPP,MOZART_MOSAIC_4BIN_KPP, MOZART_MOSAIC_4BIN_AQ_KPP )
        if( biomass_burn_opt == BIOMASSB_MOZC .or. biomass_burn_opt == BIOMASSB_MOZ ) then
          do j=jts,jte
            do k=kts,kte
              do i=its,ite
                conv_rho = (r_q*4.828e-4*dtstep)/(rho_phy(i,k,j)*60.*dz8w(i,k,j))
                chem(i,k,j,p_co)  = chem(i,k,j,p_co) + ebu(i,k,j,p_ebu_co)*conv_rho
                chem(i,k,j,p_no)  = chem(i,k,j,p_no) + ebu(i,k,j,p_ebu_no)*conv_rho
                chem(i,k,j,p_no2) = chem(i,k,j,p_no2) + ebu(i,k,j,p_ebu_no2)*conv_rho
                chem(i,k,j,p_bigalk) =  chem(i,k,j,p_bigalk) + ebu(i,k,j,p_ebu_bigalk)*conv_rho
                chem(i,k,j,p_bigene) =  chem(i,k,j,p_bigene) + ebu(i,k,j,p_ebu_bigene)*conv_rho
                chem(i,k,j,p_c2h4)   = chem(i,k,j,p_c2h4) + ebu(i,k,j,p_ebu_c2h4)*conv_rho
                chem(i,k,j,p_c2h5oh) = chem(i,k,j,p_c2h5oh) + ebu(i,k,j,p_ebu_c2h5oh)*conv_rho
                chem(i,k,j,p_c2h6) = chem(i,k,j,p_c2h6) + ebu(i,k,j,p_ebu_c2h6)*conv_rho
                chem(i,k,j,p_c3h6) = chem(i,k,j,p_c3h6) + ebu(i,k,j,p_ebu_c3h6)*conv_rho
                chem(i,k,j,p_c3h8) = chem(i,k,j,p_c3h8) + ebu(i,k,j,p_ebu_c3h8)*conv_rho
                chem(i,k,j,p_hcho) = chem(i,k,j,p_hcho) +ebu(i,k,j,p_ebu_ch2o)*conv_rho
                chem(i,k,j,p_ald)  = chem(i,k,j,p_ald) +ebu(i,k,j,p_ebu_ch3cho)*conv_rho
                chem(i,k,j,p_acetol) = chem(i,k,j,p_acetol) +ebu(i,k,j,p_ebu_acetol)*conv_rho
                chem(i,k,j,p_isopr)  = chem(i,k,j,p_isopr) +ebu(i,k,j,p_ebu_isop)*conv_rho
                chem(i,k,j,p_macr) = chem(i,k,j,p_macr) +ebu(i,k,j,p_ebu_macr)*conv_rho
                chem(i,k,j,p_mvk)  = chem(i,k,j,p_mvk) +ebu(i,k,j,p_ebu_mvk)*conv_rho
                chem(i,k,j,p_acet)  = chem(i,k,j,p_acet) + ebu(i,k,j,p_ebu_ch3coch3)*conv_rho
                chem(i,k,j,p_ch3oh) = chem(i,k,j,p_ch3oh) + ebu(i,k,j,p_ebu_ch3oh)*conv_rho
                chem(i,k,j,p_mek)  = chem(i,k,j,p_mek) + ebu(i,k,j,p_ebu_mek)*conv_rho
                chem(i,k,j,p_so2)  =  chem(i,k,j,p_so2) +ebu(i,k,j,p_ebu_so2)*conv_rho
                chem(i,k,j,p_tol)  = chem(i,k,j,p_tol) +ebu(i,k,j,p_ebu_toluene)*conv_rho
                chem(i,k,j,p_nh3)  = chem(i,k,j,p_nh3) + ebu(i,k,j,p_ebu_nh3)*conv_rho
                chem(i,k,j,p_open) = chem(i,k,j,p_open) + ebu(i,k,j,p_ebu_open)*conv_rho
                chem(i,k,j,p_c10h16) = chem(i,k,j,p_c10h16) + ebu(i,k,j,p_ebu_c10h16)*conv_rho
                chem(i,k,j,p_cres)   = chem(i,k,j,p_cres) + ebu(i,k,j,p_ebu_cres)*conv_rho
                chem(i,k,j,p_glyald) = chem(i,k,j,p_glyald) + ebu(i,k,j,p_ebu_glyald)*conv_rho
                chem(i,k,j,p_gly)    = chem(i,k,j,p_gly) + ebu(i,k,j,p_ebu_gly)*conv_rho
              enddo
            enddo
          enddo
! Adding simple SOA scheme emissions from biomass burning.
! WARNING: do not provide e_co_bb in wrfchemi* files if you use
! the online plume rise - you would be double counting emissions!
          IF (chem_opt .EQ. MOZART_MOSAIC_4BIN_KPP .OR. &
              chem_opt .EQ. MOZART_MOSAIC_4BIN_AQ_KPP) THEN
            do j=jts,jte
              do k=kts,kte
                do i=its,ite
                  conv_rho = (r_q*4.828e-4*dtstep)/(rho_phy(i,k,j)*dz8w(i,k,j)*60.)
                  chem(i,k,j,p_vocbb) = chem(i,k,j,p_vocbb) + ebu(i,k,j,p_ebu_co)*conv_rho*0.04*28./250.
                enddo
              enddo
            enddo
          ENDIF

          if( biomass_burn_opt == BIOMASSB_MOZC ) then
            do j=jts,jte
              do k=kts,kte
                do i=its,ite
                  conv_rho = (r_q*dtstep)/(rho_phy(i,k,j)*dz8w(i,k,j))
                  chem(i,k,j,p_oc1) = chem(i,k,j,p_oc1) + conv_rho*ebu(i,k,j,p_ebu_oc)
                  chem(i,k,j,p_bc1) = chem(i,k,j,p_bc1) + conv_rho*ebu(i,k,j,p_ebu_bc)
                  chem(i,k,j,p_p10) = chem(i,k,j,p_p10) + conv_rho*ebu(i,k,j,p_ebu_pm10)
                  chem(i,k,j,p_p25) = chem(i,k,j,p_p25) + conv_rho*ebu(i,k,j,p_ebu_pm25)
                enddo
              enddo
            enddo
          endif
        endif
      CASE (CHEM_TRACE2)
          do j=jts,jte
          do i=its,ite
          do k=kts+1,kte-1
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/60./dz8w(i,k,j)
        chem(i,k,j,p_tracer_1)  =  chem(i,k,j,p_tracer_1)                        &
                         +ebu(i,k,j,p_ebu_co)*conv_rho
        enddo
        k=kts
        conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/(dz8w(i,k,j)*60.)
        chem(i,k,j,p_tracer_1)  =  chem(i,k,j,p_tracer_1)                        &
                         +ebu(i,k,j,p_ebu_co)*conv_rho
        enddo
        enddo
      CASE (GHG_TRACER)
        if( biomass_burn_opt == BIOMASSB_GHG ) then
          do j=jts,jte
          do k=kts,kte
          do i=its,ite
             conv_rho=r_q*4.828e-4/rho_phy(i,k,j)*dtstep/60./dz8w(i,k,j)
             chem(i,k,j,p_co_bbu)  = chem(i,k,j,p_co_bbu)   +ebu(i,k,j,p_ebu_co)*conv_rho
             chem(i,k,j,p_co2_bbu)   = chem(i,k,j,p_co2_bbu)  +ebu(i,k,j,p_ebu_co2)*conv_rho
             chem(i,k,j,p_ch4_bbu) =  chem(i,k,j,p_ch4_bbu) + ebu(i,k,j,p_ebu_ch4)*conv_rho
          enddo
          enddo
          enddo
        endif
    CASE DEFAULT
       call wrf_debug(15,'nothing done with burn emissions for chem array')
    END SELECT emiss_select


    END subroutine add_emis_burn

END Module module_add_emiss_burn
