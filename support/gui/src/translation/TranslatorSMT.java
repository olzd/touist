/*
 *
 * Project TouIST, 2015. Easily formalize and solve real-world sized problems
 * using propositional logic and linear theory of reals with a nice GUI.
 *
 * https://github.com/touist/touist
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * Contributors:
 *     Alexis Comte, Abdelwahab Heba, Olivier Lezaud,
 *     Skander Ben Slimane, Maël Valais
 *
 */

package translation;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.StringReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.StringTokenizer;

/**
 * @author Abdel
 * @Modified by Mael
 */
public class TranslatorSMT {
	final private String outputFilePath = "out.smt2";
	final private String outputTableFilePath = "out.table";
	private String translatorProgramFilePath;
	private Map<Integer,String> literalsMap = new HashMap<Integer,String>();
	private List<TranslationError> errors = new ArrayList<TranslationError>();
	private String currentPath = System.getProperty("user.dir");
	private Process p;
	private List<String> options = new ArrayList<String>();

	
	public TranslatorSMT(List<String> options) {
		this.options = options;
	}
	public TranslatorSMT() {
	}
	
	public boolean translate(String touistlFilePath, String logic) throws IOException, InterruptedException {
		BufferedReader reader = new BufferedReader(new FileReader(touistlFilePath));
		return translate(reader,logic); 
	}

	public boolean translate(StringReader str, String logic) throws IOException, InterruptedException {
		BufferedReader reader = new BufferedReader(str);
		return translate(reader,logic); 
	}

	/**
	 * Calls the translator/compiler to transform the ".touistl" file to a
	 * ".dimacs" file (along with a "mapping" file). This method also calls the
	 * parsing methods parseErrors and (if the translation actually
	 * passed) parseLiteralsMapFile.
	 *
	 * @param touistlFilePath is the touistl (i.e. file produced by the GUI or
	 * given by the user) 
	 *
	 * @return true if the translation went well (migth have generated some
	 * warning though), false of fatal errors (syntax/semantic errors) happened
	 *
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean translate(BufferedReader reader, String logic) throws IOException, InterruptedException {
		final int OK = 0, ERROR = 1;

		// Check if translatorProgramFilePath is there
		// This trick is because of linux that sets "user.dir" = $HOME instead of $CWD
		File touist = new File(ClassLoader.getSystemClassLoader().getResource(".").getPath());
		String pathtouist = touist.getAbsolutePath() + File.separator + "external" + File.separator + "touist";
	
		List<String> cmd = new ArrayList<String>();
		
		cmd.add(pathtouist);
		cmd.add("-"); // touist will read input from stdin
		cmd.add("-smt2");
		cmd.add(logic);
		cmd.add("-o");
		cmd.add(outputFilePath);
		cmd.add("--detailed-position");
		cmd.addAll(options);		
		
        System.out.println("translate(): cmd executed: "+cmd.toString());
		
        this.p = Runtime.getRuntime().exec(cmd.toArray(new String[0]));

        BufferedWriter toProcess = new BufferedWriter(new OutputStreamWriter(p.getOutputStream()));
        String s = "";
        while ((s = reader.readLine())!=null) {
        	toProcess.write(s + "\n");
        }
        toProcess.flush();
        toProcess.close();
		
        int return_code = p.waitFor();
        
		BufferedReader fromProcess = new BufferedReader(new InputStreamReader(p.getInputStream()));
		List<String> linesStdout = new ArrayList<String>();
		while (fromProcess.ready())
			linesStdout.add(fromProcess.readLine());

		BufferedReader fromProcessErr = new BufferedReader(new InputStreamReader(
				this.p.getErrorStream()));
		String linesStdErr = "";
		while (fromProcessErr.ready()) {
			linesStdErr += fromProcessErr.readLine() + "\n";
		}
		fromProcessErr.close();
		fromProcess.close();

		errors = TranslationError.parse(linesStdErr);
		
		if(return_code == OK) {
		}
		return return_code == OK;
	}

	public Process getP(){
		return p;
	}

	/**
	 * Allows the user to get the path of the generated DIMACS file.
	 * @return the file path
	 */
	public String getSMTFilePath() {
		return currentPath+File.separatorChar+outputFilePath;
	}

	/**
	 * Allows the user to get a list of the errors generated by the translator.
	 * See the Error class.
	 * @return the list of warnings
	 */
	public List<TranslationError> getErrors() {
		return errors;
	}
}
