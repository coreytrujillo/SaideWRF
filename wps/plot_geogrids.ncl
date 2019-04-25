load "$WEBWXHOME/ncl_lib/functions.ncl"
load "$WEBWXHOME/ncl_lib/cmap_bw.ncl"
load "$WEBWXHOME/ncl_lib/meteo_funcs.ncl"
;
;# File wrfinput_plot.ncl --------------------------------------------------
;# 
;# Input:   WRF geo_em.d0x.nc netCDF file
;# Author:  Greg Thompson  20 Sep 2007
;#
;#--------------------------------------------------------------------------
;
begin
;

    ; Input/Output files, string for title.
;   dir_prefix = "/glade/p/ral/RAVP/gthompsn/ARW/2011Feb01/Test2_new/WPS_data"
    dir_prefix = "."
    wrffiles = (/ "geo_em.d01.nc", "geo_em.d02.nc" /)
;    wrffiles = (/ "geo_em.d01.nc" /)
    gmetafile  = "geogrids.ncgm"
    run_string  = "WRF domain"

    ; Window from the full domain to something less (set all to zero to plot whole domain).
    ibeg = (/ 0, 0, 0 /)
    iend = (/ 0, 0, 0 /)
    jbeg = (/ 0, 0, 0 /)
    jend = (/ 0, 0, 0 /)

    ; Show bounds of nested grids in the parent & show special markers (0=no, 1=yes)
    show_nests = 1
    show_markers = 1
    marker_lat = (/ 36.606 /)           ; 36.606,-97.489  ARM-SGP Ameriflux site
    marker_lon = (/  -97.489 /)

    ; Plot terrain in gray shades (0=no, 1=yes)
    plot_hgt = 1

    ; Plot vegetation type (0=no, 1=yes)
    plot_veg = 1

    ; Plot soil type (0=no, 1=yes)
    plot_soil = 0

    ; Viewport coordinates (desired but not for certain due to map projection).
    vpx1 = 0.1
    vpy1 = 0.9
    vpw1 = 0.8
    vph1 = 0.8

    ; Create our own colormap using included function.
    cmap=gen_bwcolormap()
    colors = new(162, "integer")
    colors(0) = 100
    do i = 1, 161
      colors(i) = i
    end do
    colors(160) = colors(148)
    print ("Colors 101 to 130: (" + cmap(100:129,0) + ", " + cmap(100:129,1) + ", " + cmap(100:129,2) + ")" )

    ; Open a workstation, ncgm, or postscript file.
    wks = xwk("ncgm",gmetafile)
    setvalues wks
        "wkColorMap" : cmap
;       "wsMaximumSize" : 50000000
    end setvalues

    ; Create current date/time string for annotation.
    create_string = "created " + systemfunc("date -u +" + integertochar(34) + "%T %a %d %b %Y" + integertochar(34))
    dummy = new(1,graphic)

    create_anno = create "create_anno" textItemClass wks
        "txPosXF" : vpx1+vpw1+0.005
        "txPosYF" : vpy1 - vph1
        "txFont" : "helvetica"
        "txAngleF" : 90
        "txString" : create_string
        "txFontColor" : 1
        "txJust" : "TOPLEFT"
        "txFontHeightF" : 0.010
        "txFuncCode" : "~"
    end create
    run_anno = create "run_anno" textItemClass wks   
        "txPosXF" : vpx1
        "txPosYF" : vpy1 + 0.002
        "txFont" : "helvetica"
        "txString" : run_string
        "txFontColor" : 1
        "txJust" : "BOTTOMLEFT"
        "txFontHeightF" : 0.014
    end create

    ; Create a GraphicStyle to control the primitive attributes.
    getvalues wks
        "wkDefGraphicStyleId" : gs
    end getvalues

    ; Ingest input file(s).      [Order of indicies is (time, z, y, x)].

    num_files = dimsizes(wrffiles)
    nx = new (num_files, integer)
    ny = new (num_files, integer)
    lat_LL = new (num_files, float)
    lon_LL = new (num_files, float)
    lat_UL = new (num_files, float)
    lon_UL = new (num_files, float)
    lat_UR = new (num_files, float)
    lon_UR = new (num_files, float)
    lat_LR = new (num_files, float)
    lon_LR = new (num_files, float)
    lat = new ((/num_files,5/), float)
    lon = new ((/num_files,5/), float)
    vpx = new (num_files, float)
    vpy = new (num_files, float)
    vpw = new (num_files, float)
    vph = new (num_files, float)
    mp = new (num_files, graphic)

    do i = 0, num_files-1

        file_in = dir_prefix + "/" + wrffiles(i)
        print ("Ingesting WRF netCDF file, " + file_in)
        file1 = addfile (file_in, "r") 

;        filedimdef(file1,"time",-1,True)

        ; Discover x,y dimensions.
        dims_xy = dimsizes(file1->HGT_M)
        print ("  dims_xy = " + dims_xy)
        nx(i) = dims_xy(2)
        ny(i) = dims_xy(1)
        print (" (x,y) dimensions of input data: " + nx(i) + ", " + ny(i))

        if (iend(i) .eq. 0) then
          iend(i) = nx(i) - 1
        end if
        if (jend(i) .eq. 0) then
          jend(i) = ny(i) - 1
        end if

        lat_LL(i) = file1->XLAT_M(0, jbeg(i),ibeg(i))
        lon_LL(i) = file1->XLONG_M(0, jbeg(i),ibeg(i))
        lat_UL(i) = file1->XLAT_M(0, jend(i),ibeg(i))
        lon_UL(i) = file1->XLONG_M(0, jend(i),ibeg(i))
        lat_UR(i) = file1->XLAT_M(0, jend(i),iend(i))
        lon_UR(i) = file1->XLONG_M(0, jend(i),iend(i))
        lat_LR(i) = file1->XLAT_M(0, jbeg(i),iend(i))
        lon_LR(i) = file1->XLONG_M(0, jbeg(i),iend(i))
        print (" Bounds of grid:  (" + (ibeg(i)+1) + ", " + (jbeg(i)+1) + ") -> (" + (iend(i)+1) + ", " + (jend(i)+1) + ")  equals (" + lat_LL(i) + ", " + lon_LL(i) + ") -> (" + lat_UL(i) + ", " + lon_UL(i) + ") -> (" + lat_UR(i) + ", " + lon_UR(i) + ") -> (" + lat_LR(i) + ", " + lon_LR(i) + ")" )
        lat(i,:) = (/ lat_LL(i), lat_UL(i), lat_UR(i), lat_LR(i), lat_LL(i) /)
        lon(i,:) = (/ lon_LL(i), lon_UL(i), lon_UR(i), lon_LR(i), lon_LL(i) /)

        mp(i) = create "mp" + i mapPlotClass wks
            "vpXF": vpx1
            "vpYF": vpy1
            "vpWidthF": vpw1
            "vpHeightF": vph1
            "mpDataBaseVersion"    : "Ncarg4_1"
            "mpDataSetName"        : "Earth..2"
            "mpDataResolution"     : "FinestResolution"
            "mpOutlineBoundarySets" : "National"
            "mpOutlineSpecifiers"  : (/"United States: States", "Mexico: States", "Canada: Provinces"/)
            "mpProjection"         : "LAMBERTCONFORMAL"
            "mpLambertParallel1F"  : file1@TRUELAT1
            "mpLambertParallel2F"  : file1@TRUELAT2
            "mpLambertMeridianF"   : file1@STAND_LON
            "mpLimitMode"          : "corners"
            "mpLeftCornerLatF"     : lat_LL(i)
            "mpLeftCornerLonF"     : lon_LL(i)
            "mpRightCornerLatF"    : lat_UR(i)
            "mpRightCornerLonF"    : lon_UR(i)
            "mpFillOn"             : True
            "mpGridAndLimbOn"      : True
            "mpLabelsOn"           : True
            "mpPerimOn"            : True
            "mpPerimLineColor"     : colors(124+i)
            "mpPerimLineThicknessF" : 2.0
            "mpGridSpacingF"       : 5.0
            "mpGridMaskMode"       : "MaskLand"
            "mpGridLineColor"      : 121
            "mpGridLineDashPattern" : 2
            "mpLandFillColor"      : 78
            "mpOceanFillColor"     : 107
            "mpInlandWaterFillColor" : 109
            "mpGeophysicalLineColor" : 111
            "mpUSStateLineColor"     : 150
            "mpProvincialLineColor"  : 150
            "mpNationalLineColor"  : 110
            "mpGreatCircleLinesOn"  : True
        end create
        getvalues mp(i)
            "vpXF"     : vpx(i)
            "vpYF"     : vpy(i)
            "vpWidthF" : vpw(i)
            "vpHeightF": vph(i)
        end getvalues
    end do


    do i = 0, num_files-1

        draw(mp(i))

        if (lat_UR(i)-lat_LL(i) .lt. 10.0) then
            getvalues mp(i)
                "mpLambertMeridianF"   : lon_mid
            end getvalues
            if (lon_mid.lt.-60.0 .and. lon_mid.gt.-179.0) then
                setvalues mp(i)
                    "mpFillOn"             : False
                    "mpOutlineBoundarySets" : "NoBoundaries"
                    "mpOutlineSpecifiers"  : (/"United States: Counties"/)
                    "mpNationalLineColor"  : 108
                    "mpUSStateLineThicknessF" : 2.0
                end setvalues
                draw(mp(i))
                setvalues mp(i)
                    "mpFillOn" : True
                end setvalues
            end if
        end if

        if (show_nests .eq. 1) then
            do j = i+1, num_files-1
                setvalues gs
                    "gsLineThicknessF" : 2.0
                    "gsLineColor" : colors(124+j)
                end setvalues
                NhlDataPolyline(mp(i), gs, lon(j,:), lat(j,:))
            end do
        end if
        if (show_markers .eq. 1) then
            setvalues gs
                "gsMarkerIndex" : 12
                "gsMarkerSizeF" : 0.005
                "gsMarkerColor" : colors(129)
            end setvalues
            NhlDataPolymarker(mp(i), gs, marker_lon, marker_lat)

;           x_ndcout = marker_lon*0.0
;           y_ndcout = marker_lat*0.0
;           NhlDataToNDC(mp(i), marker_lon, marker_lat, x_ndcout, y_ndcout)
;           do j = 0, dimsizes(x_ndcout)-1
;               print(" marker placed at (" + marker_lat(j) + ", " + marker_lon(j) + ") corresponding to NDC coords: (" + x_ndcout(j) + ", " + y_ndcout(j) + ")")
;           end do
        end if

        ; draw( (/create_anno, run_anno/) )
        frame(wks)
    end do


    if (plot_hgt .eq. 1) then
    do i = 0, num_files-1

        ;#--------------------------------------------------------------------------
        ; Plot terrain height.
        ;#--------------------------------------------------------------------------

        file_in = dir_prefix + "/" + wrffiles(i)
        file1 = addfile (file_in, "r") 
        terrain = file1->HGT_M(0,jbeg(i):jend(i),ibeg(i):iend(i))
        zmin = min(ndtooned(terrain))
        zmax = max(ndtooned(terrain))
        print (" Min/Max terrain height = " + zmin + ", " + zmax + "m")
        if (zmin .lt. 1.0) then
            terrain_contours = fspan(10.0, zmax-100.0, 93)
            terrain_contours(0) = 0.5
            terrain_contours(1) = 1.5
            colors(1) = 109
            colors(2:99) = colors(2:99) + 5
        else
            colors(1) = 1
            terrain_contours = fspan(zmin, zmax+50.0, 93)
        end if

        cn_field = contour(wks,MakeData(terrain, "null"), "null")
        setvalues cn_field
            "vpXF" : vpx(i)
            "vpYF" : vpy(i)
            "vpWidthF" : vpw(i)
            "vpHeightF" : vph(i)
            "tiMainString" : "Terrain height (m)"
            "tiMainFontHeightF" : 0.025
            "cnRasterModeOn" : True
            "cnRasterSmoothingOn" : False
            "cnLevelSelectionMode" : "ExplicitLevels"
            "cnLinesOn": False
            "cnLineLabelsOn": False
            "cnHighLabelsOn": False
            "cnLowLabelsOn": False  
            "cnLevels" : terrain_contours
            "cnFillOn": True
            "cnFillColors" : colors(1:94)
            "pmLabelBarWidthF" : vpw(i)*.99
            "lbLabelsOn" : True
            "lbLabelFontHeightF" : 0.010
            "lbLabelStride" : 10
            "lbTitleOn" : True
            "lbTitleString" : "(m)"
            "lbTitleFontHeightF" : 0.010
        end setvalues
      
        draw( (/mp(i), cn_field/) )
        setvalues mp(i)
            "mpFillOn" : False
        end setvalues
        draw(mp(i))
        ; draw( (/create_anno, run_anno/) )

        if (lat_UR(i)-lat_LL(i) .lt. 10.0) then
            getvalues mp(i)
                "mpLambertMeridianF"   : lon_mid
            end getvalues
            if (lon_mid.lt.-60.0 .and. lon_mid.gt.-179.0) then
                setvalues mp(i)
                    "mpFillOn"             : False
                    "mpOutlineBoundarySets" : "NoBoundaries"
                    "mpOutlineSpecifiers"  : (/"United States: Counties"/)
                    "mpNationalLineColor"  : 108
                    "mpUSStateLineThicknessF" : 2.0
                end setvalues
                if (lat_UR(i)-lat_LL(i) .lt. 2.5) then
                    setvalues mp(i)
                        "mpGridSpacingF"       : 0.1666667
                        "mpGridMaskMode"       : "MaskNone"
                    end setvalues
                end if
                draw(mp(i))
            end if
        end if

        if (show_nests .eq. 1) then
            do j = i+1, num_files-1
                setvalues gs
                    "gsLineColor" : colors(124+j)
                end setvalues
                NhlDataPolyline(mp(i), gs, lon(j,:), lat(j,:))
            end do
        end if
        if (show_markers .eq. 1) then
            NhlDataPolymarker(mp(i), gs, marker_lon, marker_lat)
        end if

        delete (cn_field)
        delete (terrain_contours)
        delete (terrain)

        frame(wks)

    end do
    end if


    if (plot_veg .eq. 1) then
    do i = 0, num_files-1

        ;#--------------------------------------------------------------------------
        ; Plot vegetation type.
        ;#--------------------------------------------------------------------------

        file_in = dir_prefix + "/" + wrffiles(i)
        file1 = addfile (file_in, "r") 
        veg_type = file1->LU_INDEX(0,jbeg(i):jend(i),ibeg(i):iend(i))

        cn_field = contour(wks,MakeData(veg_type, "null"), "null")
        setvalues cn_field
            "vpXF" : vpx(i)
            "vpYF" : vpy(i)
            "vpWidthF" : vpw(i)
            "vpHeightF" : vph(i)
            "tiMainString" : "Dominant land-use category"
            "tiMainFontHeightF" : 0.025
            "cnRasterModeOn" : True
            "cnRasterSmoothingOn" : False
            "cnLevelSelectionMode" : "ExplicitLevels"
            "cnLinesOn": False
            "cnLineLabelsOn": False
            "cnHighLabelsOn": False
            "cnLowLabelsOn": False  
            "cnLevels" : ispan(1,28,1)+0.05
            "cnFillOn": True
            "cnFillColors" : colors(133:161)
            "cnExplicitLabelBarLabelsOn" : True
            "pmLabelBarWidthF" : vpw(i)*.99
            "lbLabelsOn" : True
            "lbLabelFontHeightF" : 0.008
            "lbLabelAngleF" : -90.0
            "lbLabelAlignment" : "BoxCenters"
            "lbLabelJust" : "CenterLeft"
            "lbLabelStride" : 1
            "lbLabelStrings" : (/"Urban", "Dry_crop", "Irr_crop", "Mix_crop", "Crop_grass", "Crop_wood", "Grass", "Shrub", "Shrub_grass", "Savanna", "For.DecB", "For.DecN", "For.EverB", "For.EverN", "For.mixed", "Water", "Wetland_herb", "Wetland_wood", "Sparse_veg", "Tundra_herb", "Tundra_wood", "Tundra_mix", "Tundra_bare", "Snow_ice", "Playa", "Lava", "Sand_white", "Lake", "." /)
        end setvalues
      
        draw( (/mp(i), cn_field/) )
        setvalues mp(i)
            "mpFillOn" : False
        end setvalues
        draw(mp(i))
        ; draw( (/create_anno, run_anno/) )

        if (lat_UR(i)-lat_LL(i) .lt. 10.0) then
            getvalues mp(i)
                "mpLambertMeridianF"   : lon_mid
            end getvalues
            if (lon_mid.lt.-60.0 .and. lon_mid.gt.-179.0) then
                setvalues mp(i)
                    "mpFillOn"             : False
                    "mpOutlineBoundarySets" : "NoBoundaries"
                    "mpOutlineSpecifiers"  : (/"United States: Counties"/)
                    "mpNationalLineColor"  : 108
                    "mpUSStateLineThicknessF" : 2.0
                end setvalues
                draw(mp(i))
            end if
        end if

        if (show_nests .eq. 1) then
            do j = i+1, num_files-1
                setvalues gs
                    "gsLineColor" : colors(124+j)
                end setvalues
                NhlDataPolyline(mp(i), gs, lon(j,:), lat(j,:))
            end do
        end if
        if (show_markers .eq. 1) then
            NhlDataPolymarker(mp(i), gs, marker_lon, marker_lat)
        end if

        delete (cn_field)
        delete (veg_type)

        frame(wks)

    end do
    end if


    if (plot_soil .eq. 1) then
    do i = 0, num_files-1

        ;#--------------------------------------------------------------------------
        ; Plot dominant soil type.
        ; SOILCTOP & BOT are value 0 or 1 for each of 16 levels representing categories.
        ;#--------------------------------------------------------------------------

        file_in = dir_prefix + "/" + wrffiles(i)
        file1 = addfile (file_in, "r") 
        soil_type = file1->SOILCTOP(0,:,jbeg(i):jend(i),ibeg(i):iend(i))
        dims_3d = dimsizes(soil_type)
        max_soil_levels = dims_3d(0)
        print (" DEUBG:  max soil levels " + max_soil_levels)
        do k = 1, max_soil_levels
            soil_type(k-1,:,:) = k*soil_type(k-1,:,:)
        end do
        soil2D = dim_max(soil_type(south_north | :, west_east | :, soil_cat | :))

        cn_field = contour(wks,MakeData(soil2D, "null"), "null")
        setvalues cn_field
            "vpXF" : vpx(i)
            "vpYF" : vpy(i)
            "vpWidthF" : vpw(i)
            "vpHeightF" : vph(i)
            "tiMainString" : "Dominant soil category"
            "tiMainFontHeightF" : 0.025
            "cnRasterModeOn" : True
            "cnRasterSmoothingOn" : False
            "cnLevelSelectionMode" : "ExplicitLevels"
            "cnLinesOn": False
            "cnLineLabelsOn": False
            "cnHighLabelsOn": False
            "cnLowLabelsOn": False  
            "cnLevels" : ispan(1,18,1)+0.05
            "cnFillOn": True
            "cnFillColors" : colors(133:159)
            "cnExplicitLabelBarLabelsOn" : True
            "pmLabelBarWidthF" : vpw(i)*.99
            "lbLabelsOn" : True
            "lbLabelFontHeightF" : 0.008
            "lbLabelAngleF" : -90.0
            "lbLabelAlignment" : "BoxCenters"
            "lbLabelJust" : "CenterLeft"
            "lbLabelStride" : 1
            "lbLabelStrings" : (/"Sand", "Loamy_sand", "Sandy_loam", "Silt_loam", "Silt", "Loam", "Sandy_clay_loam", "Silty_clay_loam", "Clay_loam", "Sandy_clay", "Silty_clay", "Clay", "Organic", "Water", "Bedrock", "Other", "Playa", "Lava", "Sand_white" /)
        end setvalues
      
        draw( (/mp(i), cn_field/) )
        setvalues mp(i)
            "mpFillOn" : False
        end setvalues
        draw(mp(i))
        ; draw( (/create_anno, run_anno/) )

        if (lat_UR(i)-lat_LL(i) .lt. 10.0) then
            getvalues mp(i)
                "mpLambertMeridianF"   : lon_mid
            end getvalues
            if (lon_mid.lt.-60.0 .and. lon_mid.gt.-179.0) then
                setvalues mp(i)
                    "mpFillOn"             : False
                    "mpOutlineBoundarySets" : "NoBoundaries"
                    "mpOutlineSpecifiers"  : (/"United States: Counties"/)
                    "mpNationalLineColor"  : 108
                    "mpUSStateLineThicknessF" : 2.0
                end setvalues
                draw(mp(i))
            end if
        end if

        if (show_nests .eq. 1) then
            do j = i+1, num_files-1
                setvalues gs
                    "gsLineColor" : colors(124+j)
                end setvalues
                NhlDataPolyline(mp(i), gs, lon(j,:), lat(j,:))
            end do
        end if
        if (show_markers .eq. 1) then
            NhlDataPolymarker(mp(i), gs, marker_lon, marker_lat)
        end if

        delete (cn_field)
        delete (soil_type)
        delete (soil2D)

        frame(wks)

    end do
    end if


    delete (wks)
end


;       green_frac = file1->GREENFRAC(0,jbeg(i):jend(i),ibeg(i):iend(i))
