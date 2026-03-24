// Script do Acordeão
document.addEventListener('DOMContentLoaded', function() {
    const accordionButtons = document.getElementsByClassName("accordion-button");
    
    for (let i = 0; i < accordionButtons.length; i++) {
        accordionButtons[i].addEventListener("click", function() {
            this.classList.toggle("active");
            const panel = this.nextElementSibling;
            
            if (panel.style.maxHeight) {
                panel.style.maxHeight = null;
            } else {
                panel.style.maxHeight = panel.scrollHeight + "px";
            }
        });
    }
});