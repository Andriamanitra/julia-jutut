# Palapeligeneraattori lukee tekstitiedoston ja 
# tekee siitä palapelin jonka voi koota ohjelmoinnin
# peruskurssilla tehdyn palapeli-ohjelman avulla
# (http://www.cs.tut.fi/~opersk/S2015/@wrapper.shtml?htyo02)

type Pala
	# 1-uloitteinen unsigned array
	reunat::Array{UInt64, 1}
	# 2-uloitteinen character array
	kuva::Array{Char, 2}
	# true, jos ja vain jos pala on 
	# vasen yläkulmapala:
	alkukulma::Bool
end

# tulostaa palan muodossa yla:oik:ala:vas:kuva
# alkukulman loppuun lisätään = jotta palapeli
# voidaan koota oikein päin
function pala_str(pala::Pala)
	kuva = join(pala.kuva)
	string(join(pala.reunat, ':'), ':', kuva, pala.alkukulma ? "=" : "")
end

function pyörittele!(pala::Pala, n=0)
	# oletuksena satunnainen määrä pyöräytyksiä, muulloin n:
	n < 1 ? n = rand(1:3) : n
	# jotkut merkit kääntyvät pyöritellessä:
	rotaatiomappi = Dict('\\'=>'/', '/'=>'\\', '-'=>'|', '|'=>'-')
	for i = 1:n
		unshift!(pala.reunat, pop!(pala.reunat))
		pala.kuva = rotl90(pala.kuva)
		for it in eachindex(pala.kuva)
			pala.kuva[it] = get(rotaatiomappi, pala.kuva[it], pala.kuva[it])
		end
	end
end

function lue_tiedosto(filename)
	f = open(filename)
	# readlines palauttaa riveistä koostuvan arrayn
	lines = readlines(f)
	close(f)
	return lines
end

function tee_laskuri(n=1)
	x = 0
	laskuri = function()
		x += n
	end
	return laskuri
end

function tee_palat(arr, p_s)
	# myös \r\n sisältyy leveyteen mikä saattaa johtaa
	# ylimääräiseen whitespaceen (en pidä ongelmana)
	lev = maximum(map(length, arr))
	kork = length(arr)
	println("korkeus: $(kork)")
	println("leveys: $(lev)")

	# näiden jälkeen lev ja kork ovat siis palojen 
	# eivätkä merkkien määriä. mikäli rivit eivät mene
	# tasan loppuun lisätään whitespacea
	lev = lev % p_s > 0 ? div(lev, p_s)+1 : div(lev, p_s)
	kork = kork % p_s > 0 ? div(kork, p_s)+1 : div(kork, p_s)
	
	# reunalaskuri luo aina käyttämättömän kokonaisluvun
	reunalaskuri = tee_laskuri()
	palat = Array{Pala}(lev, kork)

	# huom: juliassa indeksointi alkaa 1:stä
	for r = 1:kork # r = rivi
		for s = 1:lev # s = sarake
			kuva = Array{Char}(p_s, p_s)
			reunat = []
			for j = 1:p_s # j = palan kuvan rivi
				for i = 1:p_s # i = palan kuvan sarake
					try
						merkki = arr[p_s*(r-1)+j][p_s*(s-1)+i]
						# newline tuottaa virheen jolloin se 
						# muutetaan whitespaceksi
						if merkki == '\r' || merkki == '\n'
							throw()
						end
						kuva[i, j] = merkki
					catch
						kuva[i, j] = ' '
					end
				end
			end
			# jos reunapala, reunaksi 0, muutoin katsotaan
			# viereistä palaa tai generoidaan uusi reuna
			# reunalaskurilla. huom: järjestyksellä on 
			# väliä koska käytetty push!(). älä sotke!
			push!(reunat, r == 1 ?  0 : palat[s, r-1].reunat[3])
			push!(reunat, s == lev ? 0 : reunalaskuri())
			push!(reunat, r == kork ? 0 : reunalaskuri())
			push!(reunat, s == 1 ? 0 : palat[s-1, r].reunat[2])
			palat[s, r] = Pala(reunat, kuva, s == 1 && r == 1)
		end
	end
	return palat
end

function tulosta_sekoitetut(palat)
	tulostettava = []
	for pala in palat
		# pyörittää palaa 0, 90, 180 tai 270 astetta
		pyörittele!(pala)
		# lisätään pala merkkijonona satunnaiseen paikkaan 
		# tulostettavien joukkoon
		insert!(tulostettava, rand(1:length(tulostettava)+1), pala_str(pala))
	end

	# koko roska tiedostoon output.txt (ylikirjoittaa vanhan)
	output_filu = open("output.txt", "w")
	for line in tulostettava
		write(output_filu, line)
		if line != tulostettava[end]
			write(output_filu, '\n')
		end
	end
	close(output_filu)
end

# tämä tulostaisi palat alkuperäisessä järjestyksessään
function tulosta_palat(palat)
	for pala in palat
		println(pala_str(pala))
	end
end

# tulostaisi palan koordinaateista [s, r]
function pp(palat, s, r)
	println(pala_str(palat[s, r]))
end

p_s = 4 # palan sivu (yleensä 3, isommatkin toimivat)
arr = lue_tiedosto("puzzle4.txt")
palat = tee_palat(arr, p_s)
tulosta_sekoitetut(palat)
