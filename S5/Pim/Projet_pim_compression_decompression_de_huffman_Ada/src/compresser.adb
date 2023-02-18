With LCA ;
With ABR_HUFFMAN ;
With SDA_Exceptions;
With Ada.Text_IO;           use Ada.Text_IO;
with Ada.Command_Line;      use Ada.Command_Line;
With Ada.Integer_Text_IO ;  use Ada.Integer_Text_IO;
with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;





procedure Compresser is

	-- Afficher l'usage.
	procedure Afficher_Usage is
	begin
		New_Line;
		Put_Line ("Usage : " & Command_Name & " [(-b)|(-bavard)] NOM_DU_FICHIER");
		New_Line;
		Put_Line ("-b  : Afficher l'arbre d'Huffman");
		New_Line;
	end Afficher_Usage;

	procedure compression(File_Name : String; Display_Tree : Boolean) is

		type T_Octet is mod 2 ** 8;	-- sur 8 bits

		procedure Afficher (Cle : in Integer; Donnee: in Character) is
		begin
			Put("(");
			put(Cle,1);
			put(") ");
			case Character'Pos(Donnee) is
			     when 0 => null;
			     when 10 => put("'\n'");
			     when others => put("'"&Donnee&"'");
			end case;

		end Afficher;

		procedure Afficher (Cle : in Character; Donnee: in Unbounded_String) is
		begin
			Put("'");
			if Character'Pos(Cle) = 10 then
				put("/n");
			else
				put(Cle);
			end if;
			put("' --> *"&To_String(Donnee));
			New_Line;
		end Afficher;

		package ABR_Integer_String is
				new ABR_HUFFMAN(T_Cle => Integer, T_Donnee=> Character, "<" => "<" );
		use ABR_Integer_String;

		package LCA_Char_Integer is
				new LCA(T_Cle => Character, T_Donnee => Integer);
		use LCA_Char_Integer;

		package LCA_String_ABR is
				new LCA(T_Cle => Integer, T_Donnee => T_ABR);
		use LCA_String_ABR;

		use ABR_Integer_String.LCA_Char_String;

		procedure Afficher_Huffman is
				new ABR_Integer_String.Affichage_Huffman(Afficher);

		procedure Afficher_LCA is
				new ABR_Integer_String.LCA_Char_String.Pour_Chaque(Afficher);

		procedure Enregistrer_Trie is
				new LCA_String_ABR.Enregistrer_Trie("<");


		Octet                        : T_Octet;
		char                         : Character;
		S                            : Stream_Access;
		Suite, suiteBit              : Unbounded_String;
		nbOctet, Inf, Sup, intValue  : Integer;
		File                         : Ada.Streams.Stream_IO.File_Type;

		--variables pointeurs
		abr       : T_ABR;
		lca_abr   : LCA_String_ABR.T_LCA;
		lca_init  : LCA_Char_Integer.T_LCA;
		lca_cell  : ABR_Integer_String.LCA_Char_String.T_LCA;
		char_int  : LCA_Char_Integer.T_CD;
		table     : ABR_Integer_String.LCA_Char_String.T_LCA;
		freq_abr1, freq_abr2  : LCA_String_ABR.T_CD;


	begin

		-- remplissage liste chainé avec couple caractère fréquence

		Open(File, In_File, File_Name);
		S := Stream(File);
		Initialiser(lca_init);
		while not End_Of_File(File) loop

            Octet := T_Octet'Input(S);
			Char := Character'Val(Octet);
			if not Cle_Presente(lca_init, Char) then
				Enregistrer(lca_init, Char, 1);
			else
				Enregistrer(lca_init, Char, La_Donnee(lca_init, Char) + 1);
			end if;

		end loop;
		Enregistrer(lca_init, '$', 0); --Caractère pour signaler la fin du fichier

		Close (File);

		---------------------------------------------------------------------------------------------

		--création liste chainé avec les couples frequence - arbre(feuille)
		Initialiser(lca_abr);
		While not Est_Vide(lca_init) loop
			Initialiser(abr);
			char_int := La_Paire(lca_init);
			Enregistrer_Cle_Donnee(abr, char_int.Donnee, char_int.Cle);
			Enregistrer_Trie(lca_abr, char_int.Donnee, abr);
			Supprimer(lca_init, char_int.Cle);
		end loop;

		-- création de l'arbre d'huffman
		while Taille(lca_abr) /= 1 loop
			freq_abr1 := Extraire_Min(lca_abr);
			freq_abr2 := Extraire_Min(lca_abr);
			Initialiser(abr);
			Enregistrer_Cle(abr, freq_abr1.Cle+freq_abr2.Cle);
			Enregistrer_abrg_abrd(abr, freq_abr1.Donnee, freq_abr2.Donnee);
			Enregistrer_Trie(lca_abr, freq_abr1.Cle+freq_abr2.Cle, abr);
		end loop;

		---------------------------------------------------------------------------------------------

		freq_abr1 := Extraire_Min(lca_abr);
		ABR_Integer_String.LCA_Char_String.Initialiser(table);

		Table_Huffman(freq_abr1.Donnee, table, Suite);

		if Display_Tree then

			Afficher_LCA(table); --Affichage de la table d'huffman comme dans le sujet
			New_Line;

			Suite := Null_Unbounded_String;
			Afficher_Huffman(freq_abr1.Donnee, Suite); -- Affichage de l'arbre d'huffman comme dans le sujet

		end if;

		---------------------------------------------------------------------------------------------


		Open(File, In_File, File_Name);
		S := Stream(File);

		-- creation d'une chaine de caractère correspondant au fichier à compresser
		--en remplacant les caracteres par leur codage dans l'arbre d'huffman
		while not End_Of_File(File) loop

			Octet := T_Octet'Input(S);
			Char := Character'Val(Octet);
			suiteBit := suiteBit & La_Donnee(table,Char);

		end loop;
		Close(File);

		Suite := Null_Unbounded_String;

		Code_Huffman(abr, Suite); --représentation binaire de l'arbre d'huffman page 8/16 sujet

		suiteBit := suiteBit & La_Donnee(table, '$'); --on rajoute le codage du caractère de fin à la fin du suiteBit
		suiteBit := Suite & suiteBit; --on rajoute la représentation binaire de l'arbre avan le suiteBit transcrit;


		nbOctet := Length(suiteBit) / 8; --le nombre d'octet à ecrire dans le fichier compressé


		---------------------------------------------------------------------------------------------

		Create (File, Out_File, File_Name(1..(File_Name'Last - 4)) & "_compresse.hff");
		S := Stream (File);


		--ajout au début du fichier des caractères de l'arbre
		lca_cell := table;
		while not Est_Vide(lca_cell) loop
			intValue := Character'Pos(La_Paire(lca_cell).Cle);
			T_Octet'Write(S, T_Octet(intValue));
			lca_cell := La_Cell_Next(lca_cell);
		end loop;
		T_Octet'Write(S, T_Octet(intValue));

		for i in 0..(nbOctet-1) loop
			Inf := i*8 + 1;
			Sup := i*8 + 8;
			intValue := Integer'Value("2#"&To_String(suiteBit)(Inf..Sup)&"#"); --Pour donner la val en entier(ascii)
			T_Octet'Write(S, T_Octet(intValue));
		end loop;

		if Length(suiteBit) mod 8 /= 0 then -- dans le cas où le suiteBit n'es pas un multiple de 8 pour le reste des caractères on les complète avec un 0 pour avoir 8 bit soit un octet;
			Inf := nbOctet*8 + 1;
			Sup := Length(suiteBit);
			suiteBit := To_Unbounded_String(To_String(suiteBit)(Inf..Sup));
			for i in 1..(8-Length(suiteBit)) loop
				suiteBit := suiteBit & To_Unbounded_String("0");
			end loop;
			intValue := Integer'Value("2#"&To_String(suiteBit)&"#");
			T_Octet'Write(S, T_Octet(intValue));
		end if;

		Close (File);
		vider(table);
		Vider(lca_init);
		Vider(lca_cell);
		Vider(abr);
		Vider(lca_abr);
	end compression;

begin
	if Argument_Count > 2 or Argument_Count < 1 then
		Afficher_Usage;
	else
		if Argument_Count = 2 then
			if Argument(1) =  "-b" or Argument(1) = "-bavard" then
				compression(Argument(2), true);
			else
				Afficher_Usage;
			end if;
		else
			compression(Argument(1), false);
		end if;
	end if;

exception
	when Constraint_Error =>
		Afficher_Usage;
end Compresser;
