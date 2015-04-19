/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package gui.editionView.solverSelection;

import gui.AbstractComponentPanel;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.ArrayList;
import java.util.List;

import javax.swing.ButtonGroup;
import javax.swing.JRadioButton;

/**
 *
 * @author Skander
 */
public class SolverSelectionPanel extends AbstractComponentPanel {

    private ButtonGroup group;
    private List<JRadioButton> buttons = new ArrayList<JRadioButton>();
    
    /**
     * Creates new form SolverSelectionPanel
     */
    public SolverSelectionPanel() {
        initComponents();
        group = new ButtonGroup();
        initSupportedSolvers();
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jPanelButtonsContainer = new javax.swing.JPanel();
        jScrollPane1 = new javax.swing.JScrollPane();
        jTextArea1 = new javax.swing.JTextArea();

        jPanelButtonsContainer.setName("jPanelButtonsContainer"); // NOI18N
        jPanelButtonsContainer.setLayout(new java.awt.FlowLayout(java.awt.FlowLayout.LEFT));

        jScrollPane1.setName("jScrollPane1"); // NOI18N

        jTextArea1.setEditable(false);
        jTextArea1.setColumns(20);
        jTextArea1.setRows(5);
        jTextArea1.setName("jTextArea1"); // NOI18N
        jScrollPane1.setViewportView(jTextArea1);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(jPanelButtonsContainer, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 380, Short.MAX_VALUE)
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(jPanelButtonsContainer, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addGap(18, 18, 18)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 261, Short.MAX_VALUE)
                .addContainerGap())
        );
    }// </editor-fold>//GEN-END:initComponents


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JPanel jPanelButtonsContainer;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTextArea jTextArea1;
    // End of variables declaration//GEN-END:variables

    @Override
    public void updateLanguage() {
        //TODO
    }

    private void initSupportedSolvers() {
        for(SupportedSolver solver : SupportedSolver.values()) {
            JRadioButton radioButton = new JRadioButton(solver.getName());
            radioButton.addActionListener(new ActionListener() {

                @Override
                public void actionPerformed(ActionEvent e) {
                    radioButtonHandler();
                }
            });
            group.add(radioButton);
            jPanelButtonsContainer.add(radioButton);
            buttons.add(radioButton);
        }
        buttons.get(0).setSelected(true);
        jTextArea1.setText(SupportedSolver.values()[0].getDescription());
    }

    private void radioButtonHandler() {
        for (JRadioButton button : buttons) {
            if(button.isSelected()) {
                SupportedSolver currentSolver = SupportedSolver.valueOf(
                        button.getText()
                );
                jTextArea1.setText(currentSolver.getDescription());
                break;
            }
        }
    }
}
